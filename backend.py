#4:19pm 10-11-25
#History
# ---------------------------------------------------------
# 📦 Required installs:
# pip install fastapi uvicorn pyngrok transformers accelerate sentencepiece nest_asyncio \
# sentence-transformers faiss-cpu rank-bm25 langdetect torch --upgrade
# ---------------------------------------------------------

import os, re, time, torch, nest_asyncio, uvicorn
from typing import List
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from pyngrok import ngrok, conf

from sentence_transformers import SentenceTransformer, util, CrossEncoder
from rank_bm25 import BM25Okapi
from transformers import (
    AutoModelForCausalLM, AutoTokenizer, pipeline,
    AutoModelForSeq2SeqLM
)
from langdetect import detect

# ---------------------------------------------------------
# 🌍 CONFIG
# ---------------------------------------------------------
conf.get_default().auth_token = ""
UPLOAD_DIR = "uploads"
VECTOR_DIR = "vector_store"
VECTOR_PATH = os.path.join(VECTOR_DIR, "knowledge_base.pt")
EMBED_MODEL = "intfloat/e5-base-v2"
RERANK_MODEL = "cross-encoder/ms-marco-MiniLM-L-6-v2"
GEN_MODEL_ID_EN = "microsoft/phi-2"
TRANSLATION_MODEL = "facebook/nllb-200-1.3B"
PORT = 7860

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(VECTOR_DIR, exist_ok=True)
device = "cuda" if torch.cuda.is_available() else "cpu"

# ---------------------------------------------------------
# 🚀 Load Generator Model
# ---------------------------------------------------------
print("🚀 Loading phi-2 for ENGLISH...")
tok_phi = AutoTokenizer.from_pretrained(GEN_MODEL_ID_EN)
mod_phi = AutoModelForCausalLM.from_pretrained(
    GEN_MODEL_ID_EN,
    dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
)
generator_phi = pipeline("text-generation", model=mod_phi, tokenizer=tok_phi, device_map="auto")

# ---------------------------------------------------------
# 🌐 Load NLLB Translation Model
# ---------------------------------------------------------
print(f"🌐 Loading translation model: {TRANSLATION_MODEL}")
tok_trans = AutoTokenizer.from_pretrained(TRANSLATION_MODEL)
mod_trans = AutoModelForSeq2SeqLM.from_pretrained(
    TRANSLATION_MODEL,
    dtype=torch.float16 if torch.cuda.is_available() else torch.float32
).to(device)

translator_en_ml = pipeline(
    "translation",
    model=mod_trans,
    tokenizer=tok_trans,
    src_lang="eng_Latn",
    tgt_lang="mal_Mlym",
    device=0 if torch.cuda.is_available() else -1
)

translator_ml_en = pipeline(
    "translation",
    model=mod_trans,
    tokenizer=tok_trans,
    src_lang="mal_Mlym",
    tgt_lang="eng_Latn",
    device=0 if torch.cuda.is_available() else -1
)

def translate_en_to_ml(text: str) -> str:
    if not text.strip(): return text
    return translator_en_ml(text, max_length=512)[0]['translation_text']

def translate_ml_to_en(text: str) -> str:
    if not text.strip(): return text
    return translator_ml_en(text, max_length=512)[0]['translation_text']

# ---------------------------------------------------------
# 🧠 Embedder & Reranker
# ---------------------------------------------------------
embedder = SentenceTransformer(EMBED_MODEL, device=device)
reranker = CrossEncoder(RERANK_MODEL, device=device)

RETRIEVAL_THRESHOLD = 0.10
HYBRID_THRESHOLD = 0.15

def _normalize(text: str) -> str:
    return re.sub(r'[ \t]+', ' ', text.replace("\r\n", "\n").replace("\r", "\n")).strip()

def _split_to_chunks(text: str, chunk_size: int = 700, overlap: int = 150):
    paras = [p.strip() for p in text.split("\n\n") if p.strip()]
    sents = []
    for p in paras:
        sents.extend([s for s in re.split(r'(?<=[.!?])\s+', p) if s.strip()])

    chunks, cur = [], []; cur_len = 0
    for s in sents:
        if cur_len + len(s) <= chunk_size:
            cur.append(s); cur_len += len(s) + 1
        else:
            if cur: chunks.append(" ".join(cur).strip())
            if overlap > 0 and chunks:
                tail = chunks[-1][-overlap:]
                cur = [tail + " " + s]
                cur_len = len(tail) + 1 + len(s)
            else:
                cur, cur_len = [s], len(s)
    if cur: chunks.append(" ".join(cur).strip())
    return [c for c in chunks if len(c) > 60]

# ✅ Safe conversion for both dict & string
def _prepare_bm25_corpus(chunks: List):
    def to_text(c):
        if isinstance(c, dict):
            return c.get("text", "")
        return str(c)
    tokenized = [[w.lower() for w in re.findall(r"[a-z0-9\u0D00-\u0D7F]+", to_text(c).lower())] for c in chunks]
    return tokenized, BM25Okapi(tokenized)

def _length_style(q: str):
    ql = q.lower()
    if any(k in ql for k in ["who", "when", "where", "name", "which", "ആരാണ്"]):
        return ("a single short factual sentence.", 80, 0.0)
    if any(k in ql for k in ["explain", "describe", "discuss", "വിശദമായി"]):
        return ("a detailed paragraph (5–6 sentences) ONLY from the context.", 300, 0.2)
    return ("a short and clean 1–2 sentence answer.", 160, 0.1)

# ---------------------------------------------------------
# Build / Load DB
# ---------------------------------------------------------
def build_vector_db():
    all_text = []
    for fn in os.listdir(UPLOAD_DIR):
        if fn.lower().endswith(".txt"):
            with open(os.path.join(UPLOAD_DIR, fn), "r", encoding="utf-8", errors="ignore") as f:
                all_text.append(f.read())
    if not all_text:
        print("⚠️ No .txt found.")
        return 0

    raw = _normalize("\n\n".join(all_text))
    english_chunks = _split_to_chunks(raw, 700, 150)

    texts_to_embed = english_chunks
    embs = embedder.encode(texts_to_embed, convert_to_tensor=True).cpu()
    tokenized, _ = _prepare_bm25_corpus(texts_to_embed)

    db = {
        "chunks": texts_to_embed,
        "embeddings": embs,
        "bm25_tokens": tokenized,
        "meta": {
            "embed_model": EMBED_MODEL,
            "built_at": time.time(),
        }
    }
    torch.save(db, VECTOR_PATH)
    print(f"✅ DB saved with {len(english_chunks)} chunks.")
    return len(english_chunks)

def load_db():
    if not os.path.exists(VECTOR_PATH):
        build_vector_db()
    db = torch.load(VECTOR_PATH, map_location="cpu")
    _, bm25 = _prepare_bm25_corpus(db["chunks"])
    db["_bm25"] = bm25
    return db

DB = load_db()

# ---------------------------------------------------------
# 🚀 FASTAPI
# ---------------------------------------------------------
app = FastAPI()

@app.post("/generate")
async def generate(request: Request):
    body = await request.json()
    question = (body.get("question") or "").strip()
    if not question:
        return JSONResponse({"response": "⚠️ Empty question."}, status_code=400)

    try:
        lang = detect(question)
    except:
        lang = "en"
    lang_code = "ml" if lang == "ml" else "en"

    global DB
    if DB is None:
        DB = load_db()
        if DB is None:
            return JSONResponse({"response": "⚠️ Knowledge base empty."}, status_code=400)

    chunks = DB["chunks"]
    bm25 = DB["_bm25"]

    # --- Retrieval ---
    q_text = question if lang_code == "en" else translate_ml_to_en(question)
    q_emb = embedder.encode(q_text.lower(), convert_to_tensor=True)
    sem = util.cos_sim(q_emb, DB["embeddings"].to(q_emb.device)).squeeze(0).cpu().numpy()
    token_q = [w for w in re.findall(r"[a-z0-9\u0D00-\u0D7F]+", q_text.lower())]
    bm = bm25.get_scores(token_q)

    import numpy as np
    def norm(a):
        a = np.array(a, dtype="float32"); lo, hi = a.min(), a.max()
        return (a - lo) / (hi - lo + 1e-8) if hi > lo else np.zeros_like(a)

    sem_n = norm(sem); bm_n = norm(bm)
    hybrid = 0.6 * sem_n + 0.4 * bm_n

    top_idx = np.argsort(-hybrid)[:min(30, len(chunks))]
    candidates = [(q_text, chunks[i] if isinstance(chunks[i], str) else chunks[i].get("text", "")) for i in top_idx]
    ce_scores = reranker.predict(candidates)
    reranked = sorted(zip(top_idx, ce_scores), key=lambda x: -x[1])[:6]
    final_chunks = [chunks[i] if isinstance(chunks[i], str) else chunks[i].get("text", "") for i, _ in reranked]

    if not final_chunks:
        return JSONResponse({"response": "I don’t know about that."})

    context = "\n".join(final_chunks)
    tone, max_new, temp = _length_style(question)

    # 🧠 STRICT GENERATION PROMPT
    eng_prompt = f"""
You are a strict, factual assistant.
RULES:
- Use ONLY the context provided below.
- Provide {tone}
- DO NOT output anything except the final answer.
- DO NOT add explanations, options, MCQs, Hindi text, or unrelated information.
- If you don't find the answer in context, say exactly: "I don’t know about that."

Context:
{context}

Question:
{q_text}

Answer:
""".strip()

    out = generator_phi(eng_prompt, max_new_tokens=max_new, do_sample=False)
    eng_ans_raw = out[0]["generated_text"].split("Answer:")[-1].strip()

    # 🧹 Cleanup for Hindi or trailing junk
    eng_ans = re.split(r'(Problem\s*\d*:|Option\s*[A-D]:|क्या|प्रश्न|Answer\s*:)', eng_ans_raw)[0].strip()
    eng_ans = re.sub(r'[^\S\r\n]+', ' ', eng_ans).strip()
    if len(eng_ans.split()) > 120:
        eng_ans = " ".join(eng_ans.split()[:120])

    # 🌐 Translate if needed
    answer = translate_en_to_ml(eng_ans) if lang_code == "ml" else eng_ans

    return JSONResponse({"response": answer})

@app.get("/status")
async def status():
    global DB
    if DB is None:
        return JSONResponse({"status": "empty"})
    meta = DB["meta"]
    return JSONResponse({
        "status": "ready",
        "num_chunks": len(DB["chunks"]),
        "embed_model": meta["embed_model"],
        "built_at": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(meta["built_at"]))
    })

# ---------------------------------------------------------
# 🌐 Run
# ---------------------------------------------------------
nest_asyncio.apply()
ngrok.kill()
public_url = ngrok.connect(PORT)
print(f"✅ Public URL: {public_url.public_url}")
print(f"🔗 POST → {public_url.public_url}/generate")
print(f"ℹ️ Status → {public_url.public_url}/status")

config = uvicorn.Config(app=app, host="0.0.0.0", port=PORT, log_level="info")
server = uvicorn.Server(config)
await server.serve()

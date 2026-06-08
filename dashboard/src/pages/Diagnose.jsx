import { useRef, useState } from 'react'
import api from '../api/client'

const CONF_COLOR = (c) => c >= 80 ? '#2E7D32' : c >= 50 ? '#E65100' : '#C62828'

export default function Diagnose() {
  const [image, setImage]       = useState(null)   // { file, preview }
  const [result, setResult]     = useState(null)
  const [loading, setLoading]   = useState(false)
  const [error, setError]       = useState('')
  const [dragging, setDragging] = useState(false)
  const inputRef = useRef()

  function selectFile(file) {
    if (!file) return
    if (!['image/png', 'image/jpeg', 'image/webp'].includes(file.type)) {
      setError('Please upload a PNG, JPG, or WEBP image.')
      return
    }
    setError('')
    setResult(null)
    setImage({ file, preview: URL.createObjectURL(file) })
  }

  function onDrop(e) {
    e.preventDefault()
    setDragging(false)
    selectFile(e.dataTransfer.files[0])
  }

  async function diagnose() {
    if (!image) return
    setLoading(true)
    setError('')
    setResult(null)
    try {
      const form = new FormData()
      form.append('image', image.file)
      const res = await api.post('/predict', form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      if (res.data.success) setResult(res.data.result)
      else setError(res.data.message || 'Diagnosis failed.')
    } catch (e) {
      setError(e.response?.data?.message || 'Server error. Check backend connection.')
    } finally {
      setLoading(false)
    }
  }

  function reset() {
    setImage(null)
    setResult(null)
    setError('')
  }

  return (
    <>
      <div className="page-header">
        <div>
          <h1>🔬 Diagnose Cashew Leaf</h1>
          <p>Upload a photo to assess disease with the AI model</p>
        </div>
      </div>

      <div className="row" style={{ alignItems: 'flex-start' }}>
        {/* Upload panel */}
        <div className="col" style={{ maxWidth: 480 }}>
          <div className="card" style={{ padding: '1.4rem' }}>
            <div
              className="card-header"
              style={{ padding: 0, border: 'none', marginBottom: '1rem' }}
            >
              📷 Image Upload
            </div>

            {error && <div className="alert alert-error">{error}</div>}

            {/* Drop zone */}
            <div
              onDragOver={(e) => { e.preventDefault(); setDragging(true) }}
              onDragLeave={() => setDragging(false)}
              onDrop={onDrop}
              onClick={() => !image && inputRef.current.click()}
              style={{
                border: `2px dashed ${dragging ? '#4CAF50' : '#ccc'}`,
                borderRadius: 12,
                background: dragging ? '#F1F8E9' : '#FAFAFA',
                minHeight: 220,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: image ? 'default' : 'pointer',
                transition: 'all .15s',
                overflow: 'hidden',
                position: 'relative',
              }}
            >
              {image ? (
                <img
                  src={image.preview}
                  alt="Selected leaf"
                  style={{ width: '100%', maxHeight: 280, objectFit: 'contain' }}
                />
              ) : (
                <>
                  <span style={{ fontSize: '3rem' }}>🌿</span>
                  <p style={{ marginTop: 12, color: '#888', fontSize: '.85rem', textAlign: 'center' }}>
                    Drag &amp; drop an image here<br />or <strong style={{ color: '#2E7D32' }}>click to browse</strong>
                  </p>
                  <p style={{ color: '#bbb', fontSize: '.75rem', marginTop: 6 }}>PNG · JPG · WEBP</p>
                </>
              )}
            </div>

            <input
              ref={inputRef}
              type="file"
              accept="image/png,image/jpeg,image/webp"
              style={{ display: 'none' }}
              onChange={(e) => selectFile(e.target.files[0])}
            />

            <div style={{ display: 'flex', gap: 8, marginTop: '1rem' }}>
              {!image ? (
                <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => inputRef.current.click()}>
                  📁 Choose Image
                </button>
              ) : (
                <>
                  <button
                    className="btn btn-primary"
                    style={{ flex: 1 }}
                    onClick={diagnose}
                    disabled={loading}
                  >
                    {loading
                      ? <><span className="spinner" /> Analyzing…</>
                      : '🤖 Run Diagnosis'}
                  </button>
                  <button className="btn btn-outline" onClick={reset}>✕ Clear</button>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Result panel */}
        <div className="col">
          {!result && !loading && (
            <div className="card">
              <div className="empty-state">
                <span>🔬</span>
                Upload an image and click <strong>Run Diagnosis</strong><br />to see results here.
              </div>
            </div>
          )}

          {loading && (
            <div className="card">
              <div className="empty-state">
                <span>⏳</span>Analyzing image…
              </div>
            </div>
          )}

          {result && <ResultCard result={result} />}
        </div>
      </div>
    </>
  )
}

function ResultCard({ result }) {
  const conf = Math.round(result.confidence ?? 0)
  const isHealthy = result.is_healthy

  return (
    <div className="card" style={{ padding: '1.4rem' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: '1.2rem' }}>
        <span style={{ fontSize: '2rem' }}>{isHealthy ? '✅' : '⚠️'}</span>
        <div>
          <div style={{ fontWeight: 700, fontSize: '1.05rem', color: isHealthy ? '#1B5E20' : '#B71C1C' }}>
            {result.disease_name}
          </div>
          <div style={{ fontSize: '.78rem', color: '#888' }}>
            {isHealthy ? 'Leaf is healthy' : 'Disease detected'}
          </div>
        </div>
        <span
          className={`badge ${isHealthy ? 'badge-green' : 'badge-red'}`}
          style={{ marginLeft: 'auto', fontSize: '.8rem' }}
        >
          {conf}% confidence
        </span>
      </div>

      {/* Confidence bar */}
      <div style={{ marginBottom: '1.2rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '.75rem', color: '#888', marginBottom: 4 }}>
          <span>Confidence</span><span>{conf}%</span>
        </div>
        <div style={{ height: 8, background: '#eee', borderRadius: 4, overflow: 'hidden' }}>
          <div style={{ height: '100%', width: `${conf}%`, background: CONF_COLOR(conf), borderRadius: 4, transition: 'width .4s' }} />
        </div>
      </div>

      {result.description && (
        <Section title="Description" text={result.description} />
      )}

      {!isHealthy && result.pesticide_name && (
        <div style={{ background: '#E3F2FD', borderRadius: 10, padding: '1rem', marginBottom: '1rem' }}>
          <div style={{ fontWeight: 600, fontSize: '.82rem', color: '#1565C0', marginBottom: 4 }}>
            💧 Recommended Pesticide
          </div>
          <div style={{ fontWeight: 700, fontSize: '1rem' }}>{result.pesticide_name}</div>
          {result.recommendation && result.recommendation !== result.pesticide_name && (
            <div style={{ fontSize: '.78rem', color: '#555', marginTop: 4 }}>All options: {result.recommendation}</div>
          )}
          {result.dosage && <KV label="Frequency" value={result.dosage} />}
          {result.application_method && <KV label="Best time" value={result.application_method} />}
        </div>
      )}

      {result.prevention && (
        <Section title="Prevention" text={result.prevention} />
      )}

      {result.all_scores && (
        <details style={{ marginTop: '1rem' }}>
          <summary style={{ cursor: 'pointer', fontSize: '.78rem', color: '#888' }}>All class scores</summary>
          <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 4 }}>
            {Object.entries(result.all_scores).map(([k, v]) => (
              <div key={k} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '.78rem' }}>
                <span style={{ color: '#555' }}>{k}</span>
                <span style={{ fontWeight: 600 }}>{v}</span>
              </div>
            ))}
          </div>
        </details>
      )}
    </div>
  )
}

function Section({ title, text }) {
  return (
    <div style={{ marginBottom: '1rem' }}>
      <div style={{ fontWeight: 600, fontSize: '.8rem', color: '#444', marginBottom: 4 }}>{title}</div>
      <div style={{ fontSize: '.83rem', color: '#555', lineHeight: 1.55 }}>{text}</div>
    </div>
  )
}

function KV({ label, value }) {
  return (
    <div style={{ fontSize: '.78rem', color: '#555', marginTop: 4 }}>
      <strong>{label}:</strong> {value}
    </div>
  )
}

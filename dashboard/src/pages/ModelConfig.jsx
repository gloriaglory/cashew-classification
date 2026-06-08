import { useEffect, useState } from 'react'
import api from '../api/client'

const MODELS = [
  { key: 'keras',  emoji: '🧠', title: 'Keras',  desc: 'TensorFlow .keras · 6 disease classes · Higher accuracy · Requires more memory' },
  { key: 'tflite', emoji: '⚡', title: 'TFLite', desc: 'Edge-optimised .tflite · 5 disease classes · Faster inference · Lower memory footprint' },
]

export default function ModelConfig() {
  const [active, setActive]   = useState(null)
  const [classes, setClasses] = useState([])
  const [selected, setSelected] = useState(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving]   = useState(false)
  const [msg, setMsg]         = useState(null)

  useEffect(() => {
    api.get('/admin/model').then(({ data }) => {
      setActive(data.active_model)
      setSelected(data.active_model)
      setClasses(data.classes || [])
    }).finally(() => setLoading(false))
  }, [])

  async function handleSwitch() {
    if (selected === active) return
    setSaving(true)
    setMsg(null)
    try {
      await api.post('/admin/model/switch', { model_type: selected })
      setActive(selected)
      setMsg({ type: 'success', text: `Switched to ${selected} model successfully.` })
      const { data } = await api.get('/admin/model')
      setClasses(data.classes || [])
    } catch (err) {
      setMsg({ type: 'error', text: err.response?.data?.message || 'Switch failed.' })
    } finally {
      setSaving(false)
    }
  }

  if (loading) return <div className="empty-state"><span>⏳</span>Loading…</div>

  return (
    <>
      <div className="page-header">
        <div>
          <h1>🤖 AI Model Configuration</h1>
          <p>Switch the active inference model at runtime — no server restart needed</p>
        </div>
      </div>

      {msg && <div className={`alert alert-${msg.type === 'success' ? 'success' : 'error'}`}>{msg.text}</div>}

      <div className="row" style={{ alignItems: 'flex-start' }}>
        <div style={{ width: 280, flexShrink: 0 }}>
          <div className="card" style={{ padding: '1.4rem', textAlign: 'center', marginBottom: '1rem' }}>
            <div style={{ fontSize: '2.5rem', marginBottom: 8 }}>{active === 'keras' ? '🧠' : '⚡'}</div>
            <div style={{ marginBottom: 4 }}>
              <span className={`badge badge-${active}`} style={{ fontSize: '0.85rem', padding: '4px 14px' }}>
                {active?.toUpperCase()} ACTIVE
              </span>
            </div>
            <p className="text-muted text-small mt-1">
              {active === 'keras' ? '6 disease classes' : '5 disease classes'}
            </p>
          </div>

          <div className="card" style={{ padding: '1.2rem' }}>
            <div className="fw-600 mb-1" style={{ fontSize: '.85rem' }}>Output Classes</div>
            {classes.length > 0
              ? classes.map((c, i) => (
                <span key={i} className="badge badge-green" style={{ margin: '2px', fontSize: '0.72rem' }}>{c}</span>
              ))
              : <p className="text-muted text-small">Could not load class list — check model file.</p>
            }
          </div>
        </div>

        <div className="col">
          <div className="card" style={{ padding: '1.4rem', marginBottom: '1rem' }}>
            <div className="fw-600 mb-1" style={{ fontSize: '.95rem', marginBottom: '1rem' }}>Select Model</div>
            <div className="model-options">
              {MODELS.map(m => (
                <div
                  key={m.key}
                  className={`model-option ${selected === m.key ? 'selected' : ''}`}
                  onClick={() => setSelected(m.key)}
                >
                  <div className="emoji">{m.emoji}</div>
                  <div className="fw-600">{m.title}</div>
                  <p className="text-muted text-small mt-1">{m.desc}</p>
                </div>
              ))}
            </div>
            <button
              className="btn btn-primary"
              onClick={handleSwitch}
              disabled={saving || selected === active}
            >
              {saving ? <><span className="spinner" /> Switching…</> : '↩ Apply Model Switch'}
            </button>
            {selected === active && (
              <p className="text-muted text-small mt-1">This model is already active.</p>
            )}
          </div>

          <div className="card" style={{ padding: '1.2rem' }}>
            <div className="fw-600 mb-1" style={{ fontSize: '.85rem', marginBottom: '0.8rem' }}>API Endpoint</div>
            <pre style={{ background: '#F9F9F9', borderRadius: 8, padding: '0.8rem', fontSize: '0.78rem', overflowX: 'auto', margin: 0 }}>
{`POST /api/admin/model/switch
Authorization: Bearer <admin-token>

{ "model_type": "keras" }   // or "tflite"`}
            </pre>
          </div>
        </div>
      </div>
    </>
  )
}

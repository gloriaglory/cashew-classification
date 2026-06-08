import { useEffect, useState } from 'react'
import api from '../api/client'

const EMPTY = { disease_name: '', description: '', symptoms: '', prevention: '' }

export default function Diseases() {
  const [diseases, setDiseases] = useState([])
  const [showModal, setShowModal] = useState(false)
  const [form, setForm]           = useState(EMPTY)
  const [saving, setSaving]       = useState(false)
  const [msg, setMsg]             = useState(null)

  async function load() {
    const { data } = await api.get('/admin/diseases')
    setDiseases(data.diseases || [])
  }

  useEffect(() => { load() }, [])

  async function handleAdd(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/admin/add-disease', form)
      setMsg({ type: 'success', text: 'Disease added.' })
      setShowModal(false)
      setForm(EMPTY)
      load()
    } catch (err) {
      setMsg({ type: 'error', text: err.response?.data?.message || 'Failed to add disease.' })
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete(id, name) {
    if (!confirm(`Delete "${name}"?`)) return
    await api.delete(`/admin/delete-disease/${id}`)
    load()
  }

  return (
    <>
      <div className="page-header">
        <div><h1>🦠 Diseases</h1><p>Cashew disease library</p></div>
        <button className="btn btn-primary" onClick={() => { setForm(EMPTY); setMsg(null); setShowModal(true) }}>
          + Add Disease
        </button>
      </div>

      {msg && <div className={`alert alert-${msg.type === 'success' ? 'success' : 'error'}`}>{msg.text}</div>}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1rem' }}>
        {diseases.length === 0
          ? <div className="empty-state"><span>🦠</span>No diseases added yet</div>
          : diseases.map(d => (
          <div key={d.id} className="card" style={{ padding: '1.2rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
              <strong style={{ color: '#1B5E20', fontSize: '0.95rem' }}>{d.disease_name}</strong>
              <button className="btn btn-danger btn-sm" onClick={() => handleDelete(d.id, d.disease_name)}>🗑</button>
            </div>
            <p className="text-muted text-small mb-1">{d.description?.slice(0, 100)}…</p>
            <div className="text-small mb-1"><strong>Symptoms:</strong> {d.symptoms?.slice(0, 70)}…</div>
            {d.pesticides?.length > 0 && (
              <div style={{ marginTop: 8, display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                {d.pesticides.map(p => (
                  <span key={p.id} className="badge badge-green" style={{ fontSize: '0.68rem' }}>
                    {p.pesticide_name?.slice(0, 22)}
                  </span>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>

      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Add Disease</h3>
              <button className="modal-close" onClick={() => setShowModal(false)}>×</button>
            </div>
            <form onSubmit={handleAdd}>
              <div className="modal-body">
                <div className="form-group"><label>Disease Name</label><input value={form.disease_name} onChange={e => setForm(f => ({ ...f, disease_name: e.target.value }))} required /></div>
                <div className="form-group"><label>Description</label><textarea value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} required /></div>
                <div className="row">
                  <div className="col form-group"><label>Symptoms</label><textarea value={form.symptoms} onChange={e => setForm(f => ({ ...f, symptoms: e.target.value }))} required /></div>
                  <div className="col form-group"><label>Prevention</label><textarea value={form.prevention} onChange={e => setForm(f => ({ ...f, prevention: e.target.value }))} required /></div>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-outline" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary" disabled={saving}>{saving ? 'Saving…' : 'Save Disease'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  )
}

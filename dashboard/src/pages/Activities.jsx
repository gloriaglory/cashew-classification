import { useEffect, useState } from 'react'
import api from '../api/client'

const TYPES = ['', 'DETECTION', 'LOGIN', 'REGISTER', 'LOGOUT']
const BADGE  = { DETECTION: 'badge-blue', LOGIN: 'badge-green', REGISTER: 'badge-gray', LOGOUT: 'badge-gray' }

export default function Activities() {
  const [activities, setActivities] = useState([])
  const [filter, setFilter]         = useState('')
  const [loading, setLoading]       = useState(true)

  async function load(f = filter) {
    setLoading(true)
    try {
      const { data } = await api.get('/admin/activities', { params: { filter: f, limit: 200 } })
      setActivities(data.activities || [])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load(filter) }, [filter])

  async function handleDelete(id) {
    if (!confirm('Delete this activity?')) return
    await api.delete(`/admin/activities/${id}`)
    load()
  }

  function handleExport() {
    const token = localStorage.getItem('adminToken')
    window.open(`/api/admin/activities/export?token=${token}`, '_blank')
  }

  return (
    <>
      <div className="page-header">
        <div><h1>🕐 Activities</h1><p>User action log</p></div>
        <button className="btn btn-outline" onClick={handleExport}>⬇ Export CSV</button>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: '1rem', flexWrap: 'wrap' }}>
        {TYPES.map(t => (
          <button
            key={t || 'all'}
            className={`btn ${filter === t ? 'btn-primary' : 'btn-outline'} btn-sm`}
            onClick={() => setFilter(t)}
          >
            {t || 'All'}
          </button>
        ))}
      </div>

      <div className="card">
        <div className="table-wrap">
          <table>
            <thead><tr><th>User</th><th>Type</th><th>Description</th><th>Time</th><th></th></tr></thead>
            <tbody>
              {loading
                ? <tr><td colSpan={5} className="empty-state">Loading…</td></tr>
                : activities.length === 0
                  ? <tr><td colSpan={5} className="empty-state"><span>🕐</span>No activities found</td></tr>
                  : activities.map(a => (
                <tr key={a.id}>
                  <td>
                    <div className="fw-600">{a.user_name}</div>
                    <div className="text-muted text-small">@{a.username}</div>
                  </td>
                  <td><span className={`badge ${BADGE[a.activity_type] || 'badge-gray'}`}>{a.activity_type}</span></td>
                  <td className="text-small">{a.description}</td>
                  <td className="text-muted text-small">{new Date(a.timestamp).toLocaleString()}</td>
                  <td><button className="btn btn-danger btn-sm" onClick={() => handleDelete(a.id)}>🗑</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </>
  )
}

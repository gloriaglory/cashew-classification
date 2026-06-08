import { useEffect, useState } from 'react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts'
import api from '../api/client'

const COLORS = ['#2E7D32','#43A047','#66BB6A','#81C784','#A5D6A7','#C8E6C9']

export default function Overview() {
  const [stats, setStats]    = useState(null)
  const [model, setModel]    = useState(null)
  const [recent, setRecent]  = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.get('/admin/statistics'),
      api.get('/admin/model'),
      api.get('/admin/activities?limit=12'),
    ]).then(([s, m, a]) => {
      setStats(s.data)
      setModel(m.data)
      setRecent(a.data.activities || [])
    }).finally(() => setLoading(false))
  }, [])

  if (loading) return <div className="empty-state"><span>⏳</span>Loading…</div>

  const dist = (stats?.disease_distribution || []).map(d => ({
    name: d.disease__disease_name?.split(' ').map(w => w[0]).join('') || d.name,
    fullName: d.disease__disease_name || d.name,
    count: d.count,
  }))

  return (
    <>
      <div className="page-header">
        <div>
          <h1>📊 Overview</h1>
          <p>Platform summary at a glance</p>
        </div>
        {model && (
          <span className={`badge badge-${model.active_model}`}>
            🤖 {model.active_model?.toUpperCase()} model active
          </span>
        )}
      </div>

      <div className="stat-grid">
        <StatCard icon="👥" color="#E8F5E9" iconColor="#2E7D32" label="Total Users"  value={stats?.stats?.total_users       ?? 0} />
        <StatCard icon="📷" color="#E3F2FD" iconColor="#1565C0" label="Total Scans"  value={stats?.stats?.total_detections  ?? 0} />
        <StatCard icon="✅" color="#E8F5E9" iconColor="#388E3C" label="Healthy"      value={stats?.stats?.healthy_leaves    ?? 0} />
        <StatCard icon="⚠️" color="#FFF3E0" iconColor="#E65100" label="Diseased"     value={stats?.stats?.diseased_leaves   ?? 0} />
      </div>

      <div className="row">
        <div className="col" style={{ minWidth: 280 }}>
          <div className="card">
            <div className="card-header">🦠 Disease Distribution</div>
            {dist.length > 0 ? (
              <div className="chart-wrap">
                <ResponsiveContainer width="100%" height={220}>
                  <BarChart data={dist} margin={{ top: 4, right: 10, left: -20, bottom: 0 }}>
                    <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                    <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
                    <Tooltip
                      formatter={(v, _, p) => [v, p.payload.fullName]}
                      contentStyle={{ borderRadius: 8, fontSize: 12 }}
                    />
                    <Bar dataKey="count" radius={[6,6,0,0]}>
                      {dist.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="empty-state"><span>📊</span>No detections yet</div>
            )}
          </div>
        </div>

        <div className="col" style={{ minWidth: 320, flex: 1.4 }}>
          <div className="card">
            <div className="card-header">
              🕐 Recent Activity
              <a href="/activities" className="btn btn-outline btn-sm" style={{ fontWeight: 400 }}>View all</a>
            </div>
            <div className="table-wrap">
              <table>
                <thead><tr><th>User</th><th>Action</th><th>Description</th><th>Time</th></tr></thead>
                <tbody>
                  {recent.length === 0
                    ? <tr><td colSpan={4} className="empty-state">No activities</td></tr>
                    : recent.map(a => (
                    <tr key={a.id}>
                      <td className="fw-600">@{a.username}</td>
                      <td><ActivityBadge type={a.activity_type} /></td>
                      <td className="text-muted text-small">{a.description?.slice(0, 38)}</td>
                      <td className="text-muted text-small">{formatDate(a.timestamp)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}

function StatCard({ icon, color, iconColor, label, value }) {
  return (
    <div className="stat-card">
      <div className="stat-icon" style={{ background: color, color: iconColor }}>{icon}</div>
      <div>
        <div className="stat-label">{label}</div>
        <div className="stat-value">{value}</div>
      </div>
    </div>
  )
}

function ActivityBadge({ type }) {
  const map = { DETECTION: 'badge-blue', LOGIN: 'badge-green', REGISTER: 'badge-gray', LOGOUT: 'badge-gray' }
  return <span className={`badge ${map[type] || 'badge-gray'}`}>{type}</span>
}

function formatDate(ts) {
  if (!ts) return ''
  const d = new Date(ts)
  return `${d.toLocaleDateString('en', { month: 'short', day: 'numeric' })} ${d.toLocaleTimeString('en', { hour: '2-digit', minute: '2-digit' })}`
}

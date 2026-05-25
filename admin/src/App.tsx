import { useState, useEffect } from 'react';
import axios from 'axios';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

const API = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

function App() {
  const [token, setToken] = useState(localStorage.getItem('admin_token') || '');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [analytics, setAnalytics] = useState<Record<string, number>>({});
  const [users, setUsers] = useState<Record<string, unknown>[]>([]);
  const [prompt, setPrompt] = useState('');

  const api = axios.create({
    baseURL: API,
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });

  const login = async () => {
    const res = await axios.post(`${API}/admin/login`, { email, password });
    const t = res.data.access_token;
    localStorage.setItem('admin_token', t);
    setToken(t);
  };

  useEffect(() => {
    if (!token) return;
    api.get('/admin/analytics').then((r) => setAnalytics(r.data));
    api.get('/admin/users').then((r) => setUsers(r.data));
    api.get('/admin/prompts').then((r) => {
      const p = r.data.find((x: { name: string }) => x.name === 'astrologer_default');
      if (p) setPrompt(p.system_prompt);
    });
  }, [token]);

  const savePrompt = async () => {
    await api.put('/admin/prompts/astrologer_default', { system_prompt: prompt });
    alert('Prompt updated');
  };

  if (!token) {
    return (
      <div className="login-page">
        <h1>AI Jyotish Guru Admin</h1>
        <input placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <button onClick={login}>Login</button>
      </div>
    );
  }

  const chartData = [
    { name: 'Total Users', value: analytics.total_users || 0 },
    { name: 'Premium', value: analytics.premium_users || 0 },
    { name: 'Active Subs', value: analytics.active_subscriptions || 0 },
  ];

  return (
    <div className="dashboard">
      <header>
        <h1>AI Jyotish Guru Admin</h1>
        <button onClick={() => { localStorage.removeItem('admin_token'); setToken(''); }}>
          Logout
        </button>
      </header>

      <section className="stats">
        <div className="stat-card">
          <span>Total Users</span>
          <strong>{analytics.total_users || 0}</strong>
        </div>
        <div className="stat-card">
          <span>Premium Users</span>
          <strong>{analytics.premium_users || 0}</strong>
        </div>
        <div className="stat-card">
          <span>Active Subscriptions</span>
          <strong>{analytics.active_subscriptions || 0}</strong>
        </div>
      </section>

      <section className="chart-section">
        <h2>Analytics</h2>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={chartData}>
            <XAxis dataKey="name" stroke="#b0b0c0" />
            <YAxis stroke="#b0b0c0" />
            <Tooltip />
            <Bar dataKey="value" fill="#d4af37" />
          </BarChart>
        </ResponsiveContainer>
      </section>

      <section className="users-section">
        <h2>Users</h2>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Mobile</th>
              <th>Premium</th>
              <th>Joined</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={String(u.id)}>
                <td>{String(u.full_name)}</td>
                <td>{String(u.mobile || '-')}</td>
                <td>{u.is_premium ? 'Yes' : 'No'}</td>
                <td>{String(u.created_at).split('T')[0]}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="prompt-section">
        <h2>AI Astrologer Prompt</h2>
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          rows={12}
        />
        <button onClick={savePrompt}>Save Prompt</button>
      </section>
    </div>
  );
}

export default App;

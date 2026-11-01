const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const aiCoachEngine = require('./services/ai_coach_engine');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Persistent Database Directory & File
const DATA_DIR = path.join(__dirname, 'data');
const DB_FILE = path.join(DATA_DIR, 'database.json');

if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Initial Database Baseline
const defaultDb = {
  users: [
    {
      id: 'user_001',
      name: 'حسين',
      email: 'hussin@smokii.app',
      streakDays: 14,
      lowDaysCount: 6,
      avgLevel: 'Medium',
      thisWeekProgress: 0.43,
      createdAt: new Date().toISOString(),
    },
  ],
  readings: [
    {
      id: 'read_001',
      timestamp: new Date(Date.now() - 3 * 86400000).toISOString(),
      nicotinePpm: 12.4,
      level: 'low',
      sensorBattery: 94,
      puffsDetected: 3,
      sessionDurationSeconds: 45,
      deviceStatus: 'Synced',
      notes: 'Morning breath check',
    },
    {
      id: 'read_002',
      timestamp: new Date(Date.now() - 2 * 86400000).toISOString(),
      nicotinePpm: 14.1,
      level: 'low',
      sensorBattery: 89,
      puffsDetected: 2,
      sessionDurationSeconds: 40,
      deviceStatus: 'Synced',
      notes: 'Midday check',
    },
    {
      id: 'read_003',
      timestamp: new Date(Date.now() - 1 * 86400000).toISOString(),
      nicotinePpm: 22.8,
      level: 'medium',
      sensorBattery: 82,
      puffsDetected: 7,
      sessionDurationSeconds: 60,
      deviceStatus: 'Synced',
      notes: 'Post-lunch sensor reading',
    },
    {
      id: 'read_004',
      timestamp: new Date().toISOString(),
      nicotinePpm: 11.2,
      level: 'low',
      sensorBattery: 78,
      puffsDetected: 1,
      sessionDurationSeconds: 30,
      deviceStatus: 'Connected & Calibrated',
      notes: 'Current session reading',
    },
  ],
  plan: {
    id: 'plan_001',
    title: 'SMOCII Tailored Quit Protocol',
    subtitle: 'Gradual Reduction & Smart Sensor Taper',
    targetQuitDate: '28 Days from Today',
    totalWeeks: 4,
    currentWeek: 1,
    currentDailyLimitPpm: 20.0,
    currentDailyPuffLimit: 12,
    hardwareFeedbackMessage: 'Device synchronized: baseline levels stable.',
    tasks: [
      {
        id: 'task_morning_delay',
        title: 'Morning 15-Minute Craving Delay',
        description: 'Wait at least 15 minutes after getting out of bed before taking your first puff.',
        category: 'Delay',
        timeOfDay: 'Morning',
        isCompleted: true,
      },
      {
        id: 'task_sensor_check_midday',
        title: 'Midday Sensor Health Check',
        description: 'Blow into companion sensor to measure afternoon nicotine levels.',
        category: 'Hardware Check',
        timeOfDay: 'Afternoon',
        isCompleted: false,
      },
      {
        id: 'task_water_substitution',
        title: 'Drink 2 Full Glasses of Ice Water',
        description: 'When the post-lunch urge hits, drink cold water before reaching for a smoke.',
        category: 'Behavior',
        timeOfDay: 'Afternoon',
        isCompleted: false,
      },
      {
        id: 'task_evening_reflection',
        title: 'Log Today’s Biggest Trigger in AI Coach',
        description: 'Review your day with SMOCII AI Coach to strengthen tomorrow’s resistance.',
        category: 'Mindset',
        timeOfDay: 'Evening',
        isCompleted: false,
      },
    ],
  },
};

// Load or initialize DB
let db = defaultDb;
if (fs.existsSync(DB_FILE)) {
  try {
    db = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
  } catch (e) {
    db = defaultDb;
  }
} else {
  fs.writeFileSync(DB_FILE, JSON.stringify(defaultDb, null, 2), 'utf8');
}

function saveDb() {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf8');
  } catch (err) {
    console.error('Error persisting database:', err);
  }
}

// =================== ROUTES ===================

// Health check
app.get('/api/v1/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'SMOCII Backend API',
    database: 'Persistent JSON Store Active',
    usersCount: db.users.length,
    readingsCount: db.readings.length,
    timestamp: new Date().toISOString(),
  });
});

// User Registration & Persistence
app.post('/api/v1/users/register', (req, res) => {
  const { name, email, dailyConsumption, morningTiming, triggers } = req.body;
  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required' });
  }

  const existingUser = db.users.find((u) => u.email === email);
  if (existingUser) {
    return res.json({ success: true, message: 'User logged in', user: existingUser });
  }

  const newUser = {
    id: `user_${Date.now()}`,
    name,
    email,
    dailyConsumption: dailyConsumption || 15,
    morningTiming: morningTiming || 'm_30_min',
    triggers: triggers || ['Stress'],
    streakDays: 0,
    lowDaysCount: 0,
    avgLevel: 'Low',
    thisWeekProgress: 0.1,
    createdAt: new Date().toISOString(),
  };

  db.users.push(newUser);
  saveDb();

  res.status(201).json({ success: true, message: 'User registered and saved', user: newUser });
});

// Current User Profile
app.get('/api/v1/users/me', (req, res) => {
  const user = db.users[0] || defaultDb.users[0];
  res.json(user);
});

// Empathetic AI Chatbot Endpoint
app.post('/api/v1/ai/chat', async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    const currentUser = db.users[0];
    const latestReading = db.readings[db.readings.length - 1];

    const reply = await aiCoachEngine.generateResponse({
      userMessage: message,
      userName: currentUser.name,
      latestReading,
      streakDays: currentUser.streakDays,
      currentPhase: db.plan.title,
      recentTasks: db.plan.tasks,
    });

    res.json({
      success: true,
      sender: 'SMOCII AI Coach',
      reply,
      timestamp: new Date().toISOString(),
      userContext: {
        name: currentUser.name,
        streakDays: currentUser.streakDays,
        latestPpm: latestReading.nicotinePpm,
        readingLevel: latestReading.level,
      },
    });
  } catch (err) {
    console.error('Error in /api/v1/ai/chat:', err);
    res.status(500).json({ error: 'AI Coach service error' });
  }
});

// Companion Hardware Device Ingestion (ESP32 Sensor Gateway)
app.post('/api/v1/device-data/reading', (req, res) => {
  const { nicotinePpm, sensorBattery, puffsDetected, sessionDurationSeconds, notes, macAddress } = req.body;

  if (nicotinePpm === undefined) {
    return res.status(400).json({ error: 'nicotinePpm is required' });
  }

  const ppm = parseFloat(nicotinePpm);
  let level = 'low';
  if (ppm > 32.0) {
    level = 'high';
  } else if (ppm >= 16.0) {
    level = 'medium';
  }

  const newReading = {
    id: `read_${Date.now()}`,
    timestamp: new Date().toISOString(),
    nicotinePpm: ppm,
    level,
    sensorBattery: sensorBattery || 88,
    puffsDetected: puffsDetected || 1,
    sessionDurationSeconds: sessionDurationSeconds || 30,
    macAddress: macAddress || '24:6F:28:B4:9C:12',
    deviceStatus: 'Synced via ESP32 Companion Device',
    notes: notes || 'Live breath sample recorded',
  };

  db.readings.push(newReading);

  // Automatic Treatment Plan Adaptation
  const currentUser = db.users[0];
  if (level === 'high') {
    db.plan.hardwareFeedbackMessage = `⚠️ Spike Alert: Companion sensor detected ${ppm} ppm nicotine. Protective craving protocol activated.`;
    const hasEmergency = db.plan.tasks.some((t) => t.id === 'task_emergency_spike');
    if (!hasEmergency) {
      db.plan.tasks.unshift({
        id: 'task_emergency_spike',
        title: 'Urgent: 4-7-8 Breathing & 1-Hour Puff Pause',
        description: 'Sensor detected peak nicotine. Pause all intake, drink 2 glasses of water, and allow levels to drop.',
        category: 'Behavior',
        timeOfDay: 'Immediate',
        isCompleted: false,
      });
    }
  } else if (level === 'low') {
    currentUser.streakDays += 1;
    currentUser.lowDaysCount += 1;
    currentUser.thisWeekProgress = Math.min(1.0, currentUser.thisWeekProgress + 0.08);
    db.plan.hardwareFeedbackMessage = `✅ Low Level Confirmed (${ppm} ppm). Excellent discipline! Streak reinforced.`;
  }

  saveDb();

  res.status(201).json({
    success: true,
    reading: newReading,
    intervention: {
      level,
      requiresEmergency: level === 'high',
      feedback: db.plan.hardwareFeedbackMessage,
    },
  });
});

// Hardware Reading History
app.get('/api/v1/device-data/history', (req, res) => {
  const currentUser = db.users[0];
  res.json({
    totalSessions: db.readings.length,
    streakDays: currentUser.streakDays,
    cleanRatio: '84%',
    readings: db.readings,
  });
});

// Current Treatment Plan
app.get('/api/v1/plans/current', (req, res) => {
  res.json(db.plan);
});

// Toggle Task
app.patch('/api/v1/plans/tasks/:id', (req, res) => {
  const { id } = req.params;
  const task = db.plan.tasks.find((t) => t.id === id);
  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }

  task.isCompleted = !task.isCompleted;
  saveDb();

  res.json({ success: true, task });
});

app.listen(PORT, () => {
  console.log(`🚀 SMOCII Persistent Backend running on http://localhost:${PORT}`);
  console.log(`💾 Data stored permanently in ${DB_FILE}`);
  console.log(`🤖 Empathetic AI Coach ready on http://localhost:${PORT}/api/v1/ai/chat`);
  console.log(`📡 Hardware Sensor Gateway on http://localhost:${PORT}/api/v1/device-data/reading`);
});

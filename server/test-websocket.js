#!/usr/bin/env node

/**
 * WebSocket Test Client
 *
 * Usage:
 *   node test-websocket.js <accessToken>
 *
 * Example:
 *   node test-websocket.js eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 */

const io = require('socket.io-client');

const accessToken = process.argv[2];

if (!accessToken) {
  console.error('❌ Please provide an access token as argument');
  console.log('\nUsage: node test-websocket.js <accessToken>');
  console.log('\nGet token by:');
  console.log('1. Register/Login via API');
  console.log('2. Copy the accessToken from response');
  process.exit(1);
}

const socket = io('http://localhost:3000', {
  auth: {
    token: accessToken
  }
});

console.log('🔌 Connecting to WebSocket server...\n');

// Connection events
socket.on('connect', () => {
  console.log('✅ Connected! Socket ID:', socket.id);
});

socket.on('authenticated', (data) => {
  console.log('✅ Authenticated as:', data.user.username);
  console.log('📋 User info:', JSON.stringify(data.user, null, 2));

  // Test: Join a study room
  console.log('\n📥 Testing: Join study room...');
  socket.emit('join_room', { roomId: 1 });
});

socket.on('disconnect', () => {
  console.log('❌ Disconnected from server');
});

socket.on('error', (error) => {
  console.error('❌ Error:', error);
});

// Study room events
socket.on('room_joined', (data) => {
  console.log('✅ Joined room:', data.roomCode);
  console.log('📊 Room state:', JSON.stringify(data.roomState, null, 2));

  // Test: Update energy
  console.log('\n⚡ Testing: Update energy level...');
  socket.emit('energy_update', {
    roomId: 1,
    energyLevel: 85,
    focusState: 'focused'
  });

  // Test: Send chat message
  setTimeout(() => {
    console.log('\n💬 Testing: Send chat message...');
    socket.emit('chat_message', {
      roomId: 1,
      message: 'Hello from test client!'
    });
  }, 1000);

  // Test: Start break
  setTimeout(() => {
    console.log('\n☕ Testing: Start break...');
    socket.emit('break_started', {
      roomId: 1,
      duration: 5
    });
  }, 2000);

  // Test: End break
  setTimeout(() => {
    console.log('\n🔙 Testing: End break...');
    socket.emit('break_ended', {
      roomId: 1
    });
  }, 3000);

  // Test: Leave room
  setTimeout(() => {
    console.log('\n👋 Testing: Leave room...');
    socket.emit('leave_room', {
      roomId: 1
    });

    // Disconnect after leaving
    setTimeout(() => {
      console.log('\n✅ All tests completed! Disconnecting...');
      socket.disconnect();
      process.exit(0);
    }, 1000);
  }, 4000);
});

socket.on('room_left', (data) => {
  console.log('✅ Left room:', data.roomId);
});

socket.on('user_joined', (data) => {
  console.log('👤 User joined:', data.username);
});

socket.on('user_left', (data) => {
  console.log('👋 User left:', data.username);
});

socket.on('energy_update', (data) => {
  console.log('⚡ Energy update:', `${data.username} - ${data.energyLevel}% (${data.focusState})`);
});

socket.on('focus_state_change', (data) => {
  console.log('🎯 Focus state changed:', `${data.username} - ${data.focusState}`);
});

socket.on('break_started', (data) => {
  console.log('☕ Break started:', `${data.username} - ${data.duration} minutes`);
});

socket.on('break_ended', (data) => {
  console.log('🔙 Break ended:', data.username);
});

socket.on('chat_message', (data) => {
  console.log('💬 Chat message:', `${data.username}: ${data.message}`);
});

socket.on('notification', (data) => {
  console.log('🔔 Notification:', JSON.stringify(data, null, 2));
});

// Handle Ctrl+C
process.on('SIGINT', () => {
  console.log('\n\n🛑 Disconnecting...');
  socket.disconnect();
  process.exit(0);
});

# macOS OpenVPN Testing Guide

Comprehensive testing guide for the macOS OpenVPN Flutter client.

## 🧪 Testing Strategy

### 1. **Unit Tests**
- Dart business logic
- Platform channel communication
- Configuration parsing

### 2. **Integration Tests**
- End-to-end connection flow
- Real server connectivity
- Error handling scenarios

### 3. **Manual Tests**
- UI functionality
- Performance testing
- Edge cases

## 🔧 Test Environment Setup

### Prerequisites
```bash
# Install test dependencies
flutter pub get

# Ensure OpenVPN libraries are built
./build_macos_release.sh
```

### Test Server Setup
```bash
# Use the existing test server
Server: 172.16.109.4:1194
Config: vm02.ovpn (included in project)
Protocol: OpenVPN UDP
```

## 🚀 Running Tests

### Automated Tests
```bash
# Run all Dart tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run integration tests
flutter test integration_test/
```

### Manual Testing
```bash
# Debug build
flutter run -d macos --debug

# Release build testing
flutter run -d macos --release
```

## ✅ Test Checklist

### 🏗️ **Build Tests**
- [ ] Dependencies build successfully
- [ ] OpenVPN3 Core compiles without errors
- [ ] macOS wrapper builds correctly
- [ ] Flutter app compiles for both debug and release
- [ ] Universal binary includes both architectures
- [ ] No linker warnings or errors

### 🚀 **Startup Tests**
- [ ] App launches without crashes
- [ ] OpenVPN library initializes successfully
- [ ] Platform channels establish correctly
- [ ] UI renders properly
- [ ] Status shows "disconnected" initially

### 📁 **Configuration Tests**
- [ ] Valid OpenVPN config loads successfully
- [ ] Invalid config shows appropriate error
- [ ] Missing config file handled gracefully
- [ ] Large config files (>10KB) load correctly
- [ ] Config with special characters works
- [ ] Multiple server entries parsed correctly

### 🔐 **Authentication Tests**
- [ ] Username/password authentication works
- [ ] Certificate-based authentication works
- [ ] Invalid credentials show proper error
- [ ] Empty credentials handled correctly
- [ ] Special characters in credentials work

### 🌐 **Connection Tests**
- [ ] Connection to test server succeeds
- [ ] SSL handshake completes successfully
- [ ] VPN IP address assigned correctly
- [ ] DNS servers configured properly
- [ ] Routing table updated correctly
- [ ] Connection status updates in real-time

### 📊 **Statistics Tests**
- [ ] Connection duration tracked accurately
- [ ] Bytes in/out counters work
- [ ] Server IP displayed correctly
- [ ] Local IP shown properly
- [ ] Stats update every 2 seconds
- [ ] Stats reset on disconnect

### 🔌 **Disconnection Tests**
- [ ] Manual disconnect works immediately
- [ ] App quit disconnects properly
- [ ] Network change handled gracefully
- [ ] Server-initiated disconnect handled
- [ ] Cleanup completes successfully

### 🛡️ **Security Tests**
- [ ] TLS 1.3 negotiation works
- [ ] AES-256-GCM encryption active
- [ ] Certificate validation enforced
- [ ] No plaintext data transmission
- [ ] Perfect forward secrecy enabled

### 🎯 **Performance Tests**
- [ ] Connection establishes within 10 seconds
- [ ] Memory usage remains stable
- [ ] CPU usage acceptable during connection
- [ ] No memory leaks during long sessions
- [ ] App responsive during connection process

### 🚨 **Error Handling Tests**
- [ ] Network unavailable handled gracefully
- [ ] Server unreachable shows proper error
- [ ] Invalid server address handled
- [ ] Connection timeout handled correctly
- [ ] Authentication failure shows clear message
- [ ] Certificate errors displayed properly

### 🔄 **Reconnection Tests**
- [ ] Automatic reconnection after network loss
- [ ] Manual reconnection works
- [ ] Connection survives sleep/wake cycle
- [ ] Network interface changes handled
- [ ] Multiple rapid connect/disconnect cycles

### 🖥️ **macOS Specific Tests**
- [ ] Works on Intel Macs (x86_64)
- [ ] Works on Apple Silicon Macs (arm64)
- [ ] macOS 10.15 compatibility
- [ ] macOS 11+ features work
- [ ] System VPN settings integration
- [ ] Network extension permissions

## 🐛 Common Test Scenarios

### Scenario 1: First Time Setup
```bash
# Clean environment test
rm -rf ~/Library/Preferences/com.example.fl_openvpn_client*
flutter run -d macos
# Test: First launch, permission requests, initial setup
```

### Scenario 2: Network Interruption
```bash
# During active connection:
# 1. Disconnect WiFi
# 2. Wait 30 seconds
# 3. Reconnect WiFi
# Expected: Auto-reconnection or graceful error
```

### Scenario 3: Multiple Configs
```bash
# Test with different OpenVPN configurations:
# - Different servers
# - Different authentication methods
# - Different encryption settings
# - Different compression settings
```

### Scenario 4: Long Duration Test
```bash
# Connect and leave running for 24+ hours
# Monitor: Memory usage, connection stability, stats accuracy
```

## 📋 Test Results Template

```markdown
## Test Run: [Date]

### Environment
- macOS Version: 
- Hardware: 
- Flutter Version: 
- Build Type: Debug/Release

### Results
- Build Tests: ✅/❌
- Startup Tests: ✅/❌
- Connection Tests: ✅/❌
- Performance Tests: ✅/❌
- Error Handling: ✅/❌

### Issues Found
1. [Issue description]
   - Severity: High/Medium/Low
   - Steps to reproduce:
   - Expected vs Actual:

### Performance Metrics
- Connection Time: X seconds
- Memory Usage: X MB
- CPU Usage: X%
- Battery Impact: Low/Medium/High
```

## 🔍 Debugging Failed Tests

### Enable Verbose Logging
```bash
# Run with maximum logging
flutter run -d macos --verbose

# Check system logs
log stream --predicate 'process == "fl_openvpn_client"' --level debug
```

### Common Failure Points

1. **Library Loading Issues**
   ```bash
   # Check library dependencies
   otool -L build/macos/Build/Products/Debug/fl_openvpn_client.app/Contents/MacOS/fl_openvpn_client
   ```

2. **OpenVPN Core Issues**
   ```bash
   # Look for OpenVPN3 Core logs
   grep "OpenVPN3" logs.txt
   ```

3. **Platform Channel Issues**
   ```bash
   # Check Swift-Dart communication
   grep "Platform Channel" logs.txt
   ```

## 📊 Performance Benchmarks

### Target Metrics
- **Connection Time**: < 10 seconds
- **Memory Usage**: < 100 MB
- **CPU Usage**: < 5% when idle
- **Battery Impact**: Minimal
- **Network Overhead**: < 5%

### Measurement Tools
```bash
# Memory usage
top -pid $(pgrep fl_openvpn_client)

# Network monitoring
nettop -p fl_openvpn_client

# Energy impact
powermetrics --samplers smc -n 1 | grep fl_openvpn_client
```

## 🎯 Acceptance Criteria

For a test run to be considered successful:

1. ✅ All automated tests pass
2. ✅ Manual test checklist 100% complete
3. ✅ No critical or high-severity issues
4. ✅ Performance within target metrics
5. ✅ Works on both Intel and Apple Silicon
6. ✅ Compatible with target macOS versions
7. ✅ No memory leaks or crashes
8. ✅ Proper error handling for all scenarios

## 📞 Reporting Issues

When reporting test failures:

1. **Environment Details**: macOS version, hardware, Flutter version
2. **Steps to Reproduce**: Exact sequence of actions
3. **Expected vs Actual**: What should happen vs what happened
4. **Logs**: Include relevant log excerpts
5. **Screenshots**: If UI-related
6. **Frequency**: Always/Sometimes/Rare

---

**Happy Testing! 🧪✨**

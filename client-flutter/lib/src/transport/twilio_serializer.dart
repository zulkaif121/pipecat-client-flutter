/// Copyright (c) 2024, Pipecat AI.
///
/// SPDX-License-Identifier: BSD-2-Clause

import 'dart:convert';
import 'dart:typed_data';
import '../models/rtvi_message.dart';

abstract class WebSocketSerializer {
  dynamic serialize(Map<String, dynamic> message);
  dynamic serializeMessage(RTVIMessage message);
  dynamic serializeAudio(Uint8List audioData, int sampleRate, int channels);
  Future<Map<String, dynamic>> deserialize(dynamic data);
}

class TwilioSerializer implements WebSocketSerializer {
  @override
  dynamic serialize(Map<String, dynamic> message) {
    return json.encode(message);
  }

  @override
  dynamic serializeMessage(RTVIMessage message) {
    final wrappedMessage = {
      'event': 'media',
      'media': {
        'track': 'inbound',
        'chunk': '1',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'payload': base64Encode(utf8.encode(json.encode({
          'label': 'rtvi-ai',
          ...message.toJson(),
        }))),
      },
    };
    return json.encode(wrappedMessage);
  }

  @override
  dynamic serializeAudio(Uint8List audioData, int sampleRate, int channels) {
    // Convert PCM16 to μ-law (exactly like TS client)
    final muLawData = _pcm16ToMuLaw(audioData);
    final payload = base64Encode(muLawData);
    
    final message = {
      'event': 'media',
      'media': {
        'payload': payload,
      },
    };
    
    return json.encode(message);
  }

  @override
  Future<Map<String, dynamic>> deserialize(dynamic data) async {
    if (data is String) {
      final decoded = json.decode(data) as Map<String, dynamic>;
      
      // Handle Twilio format
      if (decoded['event'] == 'media' && decoded['media'] != null) {
        final media = decoded['media'] as Map<String, dynamic>;
        final payload = media['payload'] as String?;
        
        if (payload != null) {
          try {
            // Try to decode as text message first
            final textData = utf8.decode(base64Decode(payload));
            final messageData = json.decode(textData) as Map<String, dynamic>;
            
            if (messageData['label'] == 'rtvi-ai') {
              return {
                'type': 'message',
                'message': RTVIMessage.fromJson(messageData),
              };
            }
          } catch (e) {
            // If text decoding fails, treat as audio
            final muLawData = base64Decode(payload);
            final pcm16Data = _muLawToPcm16(muLawData);
            return {
              'type': 'audio',
              'audio': pcm16Data,
            };
          }
        }
      }
      
      // Handle direct RTVI messages
      if (decoded['type'] != null) {
        return {
          'type': 'message',
          'message': RTVIMessage.fromJson(decoded),
        };
      }
    }
    
    throw Exception('Unable to deserialize message: $data');
  }

  /// Converts μ-law encoded data to PCM16 format
  /// This matches the mulaw.decode() functionality in the TS client
  Uint8List _muLawToPcm16(Uint8List muLawData) {
    // μ-law to linear conversion table (standard G.711 μ-law)
    const muLawTable = [
      -32124, -31100, -30076, -29052, -28028, -27004, -25980, -24956,
      -23932, -22908, -21884, -20860, -19836, -18812, -17788, -16764,
      -15996, -15484, -14972, -14460, -13948, -13436, -12924, -12412,
      -11900, -11388, -10876, -10364, -9852, -9340, -8828, -8316,
      -7932, -7676, -7420, -7164, -6908, -6652, -6396, -6140,
      -5884, -5628, -5372, -5116, -4860, -4604, -4348, -4092,
      -3900, -3772, -3644, -3516, -3388, -3260, -3132, -3004,
      -2876, -2748, -2620, -2492, -2364, -2236, -2108, -1980,
      -1884, -1820, -1756, -1692, -1628, -1564, -1500, -1436,
      -1372, -1308, -1244, -1180, -1116, -1052, -988, -924,
      -876, -844, -812, -780, -748, -716, -684, -652,
      -620, -588, -556, -524, -492, -460, -428, -396,
      -372, -356, -340, -324, -308, -292, -276, -260,
      -244, -228, -212, -196, -180, -164, -148, -132,
      -120, -112, -104, -96, -88, -80, -72, -64,
      -56, -48, -40, -32, -24, -16, -8, 0,
      32124, 31100, 30076, 29052, 28028, 27004, 25980, 24956,
      23932, 22908, 21884, 20860, 19836, 18812, 17788, 16764,
      15996, 15484, 14972, 14460, 13948, 13436, 12924, 12412,
      11900, 11388, 10876, 10364, 9852, 9340, 8828, 8316,
      7932, 7676, 7420, 7164, 6908, 6652, 6396, 6140,
      5884, 5628, 5372, 5116, 4860, 4604, 4348, 4092,
      3900, 3772, 3644, 3516, 3388, 3260, 3132, 3004,
      2876, 2748, 2620, 2492, 2364, 2236, 2108, 1980,
      1884, 1820, 1756, 1692, 1628, 1564, 1500, 1436,
      1372, 1308, 1244, 1180, 1116, 1052, 988, 924,
      876, 844, 812, 780, 748, 716, 684, 652,
      620, 588, 556, 524, 492, 460, 428, 396,
      372, 356, 340, 324, 308, 292, 276, 260,
      244, 228, 212, 196, 180, 164, 148, 132,
      120, 112, 104, 96, 88, 80, 72, 64,
      56, 48, 40, 32, 24, 16, 8, 0
    ];

    // Convert μ-law to PCM16 (little endian bytes)
    final pcm16Bytes = <int>[];
    
    for (int i = 0; i < muLawData.length; i++) {
      final muLawValue = muLawData[i];
      final pcm16Value = muLawTable[muLawValue];
      
      // Convert 16-bit signed integer to little endian bytes
      pcm16Bytes.add(pcm16Value & 0xFF);        // Low byte
      pcm16Bytes.add((pcm16Value >> 8) & 0xFF); // High byte
    }
    
    return Uint8List.fromList(pcm16Bytes);
  }

  /// Converts PCM16 data to μ-law format
  /// This matches the mulaw.encode() functionality in the TS client
  Uint8List _pcm16ToMuLaw(Uint8List pcm16Data) {
    final muLawBytes = <int>[];
    
    // Process PCM16 data in pairs (little endian)
    for (int i = 0; i < pcm16Data.length; i += 2) {
      if (i + 1 < pcm16Data.length) {
        // Combine two bytes into 16-bit sample (little endian)
        final sample = pcm16Data[i] | (pcm16Data[i + 1] << 8);
        // Convert unsigned to signed 16-bit
        final signed = sample > 32767 ? sample - 65536 : sample;
        // Convert to μ-law
        final muLawValue = _linearToMuLaw(signed);
        muLawBytes.add(muLawValue);
      }
    }
    
    return Uint8List.fromList(muLawBytes);
  }

  /// Converts a linear PCM16 sample to μ-law
  int _linearToMuLaw(int pcm) {
    // Standard G.711 μ-law encoding algorithm
    const int BIAS = 0x84;
    const int CLIP = 32635;
    
    int sign = (pcm >> 8) & 0x80;
    if (sign != 0) pcm = -pcm;
    if (pcm > CLIP) pcm = CLIP;
    
    pcm += BIAS;
    int exponent = 7;
    int expMask = 0x4000;
    
    for (int i = 0; i < 8; i++) {
      if ((pcm & expMask) != 0) break;
      exponent--;
      expMask >>= 1;
    }
    
    int mantissa = (pcm >> (exponent + 3)) & 0x0F;
    int muLaw = ~(sign | (exponent << 4) | mantissa);
    
    return muLaw & 0xFF;
  }
}
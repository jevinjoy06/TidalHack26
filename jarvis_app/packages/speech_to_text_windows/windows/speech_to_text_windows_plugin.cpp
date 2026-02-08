#include "speech_to_text_windows_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <sapi.h>
#include <iostream>
#include <string>

namespace speech_to_text_windows {

void SpeechToTextWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "speech_to_text_windows",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<SpeechToTextWindowsPlugin>();
  plugin->m_channel = std::move(channel);
  plugin->m_registrar = registrar;

  plugin->m_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

SpeechToTextWindowsPlugin::SpeechToTextWindowsPlugin() 
  : m_cpRecognizer(nullptr)
  , m_cpRecoContext(nullptr)
  , m_cpRecoGrammar(nullptr)
  , m_cpAudio(nullptr)
  , m_initialized(false)
  , m_listening(false) {
  std::cout << "SpeechToTextWindowsPlugin created" << std::endl;
  CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
}

SpeechToTextWindowsPlugin::~SpeechToTextWindowsPlugin() {
  std::cout << "SpeechToTextWindowsPlugin destroyed" << std::endl;
  
  std::lock_guard<std::mutex> lock(m_mutex);
  
  if (m_listening) {
    Stop(nullptr);
  }
  
  if (m_cpRecoGrammar) {
    m_cpRecoGrammar->Release();
    m_cpRecoGrammar = nullptr;
  }
  if (m_cpRecoContext) {
    m_cpRecoContext->Release();
    m_cpRecoContext = nullptr;
  }
  if (m_cpRecognizer) {
    m_cpRecognizer->Release();
    m_cpRecognizer = nullptr;
  }
  if (m_cpAudio) {
    m_cpAudio->Release();
    m_cpAudio = nullptr;
  }
  
  CoUninitialize();
}

void SpeechToTextWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const std::string& method_name = method_call.method_name();
  std::cout << "Method called: " << method_name << std::endl;
  
  if (method_name == "hasPermission") {
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "initialize") {
    Initialize(method_call, std::move(result));
  } else if (method_name == "listen") {
    Listen(method_call, std::move(result));
  } else if (method_name == "stop") {
    Stop(std::move(result));
  } else if (method_name == "cancel") {
    Cancel(std::move(result));
  } else if (method_name == "locales") {
    GetLocales(std::move(result));
  } else {
    result->NotImplemented();
  }
}

void SpeechToTextWindowsPlugin::Initialize(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  std::lock_guard<std::mutex> lock(m_mutex);
  
  if (m_initialized) {
    std::cout << "Already initialized" << std::endl;
    result->Success(flutter::EncodableValue(true));
    return;
  }

  std::cout << "Initializing SAPI speech recognition..." << std::endl;

  try {
    HRESULT hr = S_OK;

    // Create a recognition engine
    hr = CoCreateInstance(CLSID_SpInprocRecognizer, NULL, CLSCTX_INPROC_SERVER, 
                         IID_ISpRecognizer, (void**)&m_cpRecognizer);
    if (FAILED(hr)) {
      std::cout << "Failed to create speech recognizer. HRESULT: " << std::hex << hr << std::endl;
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Create default audio input
    hr = CoCreateInstance(CLSID_SpMMAudioIn, NULL, CLSCTX_INPROC_SERVER,
                         IID_ISpAudio, (void**)&m_cpAudio);
    if (FAILED(hr)) {
      std::cout << "Failed to create audio input. HRESULT: " << std::hex << hr << std::endl;
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Set the audio input to our recognizer
    hr = m_cpRecognizer->SetInput(m_cpAudio, TRUE);
    if (FAILED(hr)) {
      std::cout << "Failed to set audio input. HRESULT: " << std::hex << hr << std::endl;
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Create a recognition context
    hr = m_cpRecognizer->CreateRecoContext(&m_cpRecoContext);
    if (FAILED(hr)) {
      std::cout << "Failed to create recognition context. HRESULT: " << std::hex << hr << std::endl;
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Create a grammar
    hr = m_cpRecoContext->CreateGrammar(0, &m_cpRecoGrammar);
    if (FAILED(hr)) {
      std::cout << "Failed to create grammar. HRESULT: " << std::hex << hr << std::endl;
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Enable dictation grammar
    hr = m_cpRecoGrammar->LoadDictation(NULL, SPLO_STATIC);
    if (FAILED(hr)) {
      std::cout << "Failed to load dictation grammar. HRESULT: " << std::hex << hr << std::endl;
      result->Success(flutter::EncodableValue(false));
      return;
    }

    m_initialized = true;
    std::cout << "SAPI speech recognition initialized successfully!" << std::endl;
    result->Success(flutter::EncodableValue(true));

  } catch (...) {
    std::cout << "Exception during initialization" << std::endl;
    result->Success(flutter::EncodableValue(false));
  }
}

void SpeechToTextWindowsPlugin::Listen(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  std::lock_guard<std::mutex> lock(m_mutex);
  
  if (!m_initialized || !m_cpRecoGrammar) {
    std::cout << "Speech recognition not initialized" << std::endl;
    result->Error("NOT_INITIALIZED", "Speech recognition not initialized");
    return;
  }

  if (m_listening) {
    std::cout << "Already listening" << std::endl;
    result->Success(flutter::EncodableValue(true));
    return;
  }

  // Parse localeId from method call args (optional - can improve accuracy)
  std::string locale_id = "en-US";
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (args) {
    auto it = args->find(flutter::EncodableValue("localeId"));
    if (it != args->end()) {
      const auto* locale_str = std::get_if<std::string>(&it->second);
      if (locale_str && !locale_str->empty()) {
        locale_id = *locale_str;
      }
    }
  }

  std::cout << "Starting speech recognition (locale: " << locale_id << ")..." << std::endl;

  try {
    // Activate the grammar
    HRESULT hr = m_cpRecoGrammar->SetDictationState(SPRS_ACTIVE);
    if (FAILED(hr)) {
      std::cout << "Failed to activate dictation. HRESULT: " << std::hex << hr << std::endl;
      result->Success(flutter::EncodableValue(false));
      return;
    }

    m_listening = true;

    // Get window handle for timer-based polling on platform thread
    flutter::FlutterView* view = m_registrar ? m_registrar->GetView() : nullptr;
    if (!view) {
      std::cout << "No Flutter view - cannot start recognition" << std::endl;
      m_listening = false;
      result->Success(flutter::EncodableValue(false));
      return;
    }
    m_hwnd = view->GetNativeWindow();
    if (!m_hwnd) {
      std::cout << "No native window - cannot start recognition" << std::endl;
      m_listening = false;
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Register delegate to receive timer messages on platform thread
    m_windowProcDelegateId = m_registrar->RegisterTopLevelWindowProcDelegate(
        [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam)
            -> std::optional<LRESULT> {
          if (message == WM_TIMER && wparam == kSpeechPollTimerId) {
            ProcessRecognitionEvents();
            return 0;
          }
          return std::nullopt;
        });

    SetTimer(m_hwnd, kSpeechPollTimerId, 50, nullptr);
    SendStatus("listening");
    std::cout << "Speech recognition listening started (timer-based)!" << std::endl;
    result->Success(flutter::EncodableValue(true));

  } catch (...) {
    std::cout << "Exception during listen" << std::endl;
    result->Success(flutter::EncodableValue(false));
  }
}

void SpeechToTextWindowsPlugin::Stop(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  std::lock_guard<std::mutex> lock(m_mutex);
  
  if (m_listening) {
    std::cout << "Stopping speech recognition..." << std::endl;
    if (m_cpRecoGrammar) {
      m_cpRecoGrammar->SetDictationState(SPRS_INACTIVE);
    }
    if (m_hwnd) {
      KillTimer(m_hwnd, kSpeechPollTimerId);
      m_hwnd = nullptr;
    }
    if (m_windowProcDelegateId >= 0 && m_registrar) {
      m_registrar->UnregisterTopLevelWindowProcDelegate(m_windowProcDelegateId);
      m_windowProcDelegateId = -1;
    }
    m_listening = false;
    SendStatus("notListening");
    std::cout << "Speech recognition stopped" << std::endl;
  }
  
  if (result) {
    result->Success(flutter::EncodableValue(nullptr));
  }
}

void SpeechToTextWindowsPlugin::ProcessRecognitionEvents() {
  if (!m_listening || !m_cpRecoContext) return;

  SPEVENT event;
  ULONG fetched = 0;

  while (m_listening && m_cpRecoContext) {
    HRESULT hr = m_cpRecoContext->GetEvents(1, &event, &fetched);

    if (SUCCEEDED(hr) && fetched > 0) {
      switch (event.eEventId) {
        case SPEI_RECOGNITION: {
          ISpRecoResult* pResult = reinterpret_cast<ISpRecoResult*>(event.lParam);
          if (pResult) {
            LPWSTR pwszText = nullptr;
            hr = pResult->GetText(SP_GETWHOLEPHRASE, SP_GETWHOLEPHRASE,
                                 TRUE, &pwszText, NULL);
            if (SUCCEEDED(hr) && pwszText) {
              int size = WideCharToMultiByte(CP_UTF8, 0, pwszText, -1,
                                           nullptr, 0, nullptr, nullptr);
              if (size > 0) {
                std::string utf8Text(size - 1, '\0');
                WideCharToMultiByte(CP_UTF8, 0, pwszText, -1,
                                  &utf8Text[0], size, nullptr, nullptr);
                SendTextRecognition(utf8Text, true);
              }
              CoTaskMemFree(pwszText);
            }
            pResult->Release();
          }
          break;
        }
        case SPEI_HYPOTHESIS: {
          ISpRecoResult* pResult = reinterpret_cast<ISpRecoResult*>(event.lParam);
          if (pResult) {
            LPWSTR pwszText = nullptr;
            hr = pResult->GetText(SP_GETWHOLEPHRASE, SP_GETWHOLEPHRASE,
                                 TRUE, &pwszText, NULL);
            if (SUCCEEDED(hr) && pwszText) {
              int size = WideCharToMultiByte(CP_UTF8, 0, pwszText, -1,
                                           nullptr, 0, nullptr, nullptr);
              if (size > 0) {
                std::string utf8Text(size - 1, '\0');
                WideCharToMultiByte(CP_UTF8, 0, pwszText, -1,
                                  &utf8Text[0], size, nullptr, nullptr);
                SendTextRecognition(utf8Text, false);
              }
              CoTaskMemFree(pwszText);
            }
            pResult->Release();
          }
          break;
        }
        case SPEI_SOUND_START:
          SendStatus("soundDetected");
          break;
        case SPEI_SOUND_END:
          SendStatus("soundEnded");
          break;
        default:
          break;
      }
    } else {
      break;
    }
  }
}

void SpeechToTextWindowsPlugin::Cancel(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::cout << "Canceling speech recognition..." << std::endl;
  Stop(std::move(result));
}

void SpeechToTextWindowsPlugin::GetLocales(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  flutter::EncodableList locales;
  locales.push_back(flutter::EncodableValue("en-US:English (United States)"));
  locales.push_back(flutter::EncodableValue("en-GB:English (United Kingdom)"));
  
  result->Success(flutter::EncodableValue(locales));
}

static std::string JsonEscape(const std::string& s) {
  std::string out;
  for (char c : s) {
    if (c == '\\') out += "\\\\";
    else if (c == '"') out += "\\\"";
    else out += c;
  }
  return out;
}

void SpeechToTextWindowsPlugin::SendTextRecognition(const std::string& text, bool is_final) {
  if (!m_channel) return;
  // Ensure alternates is always a non-null array (speech_to_text expects List)
  std::string escaped = JsonEscape(text);
  std::string json_result = "{\"recognizedWords\":\"" + escaped +
                           "\",\"finalResult\":" + (is_final ? "true" : "false") +
                           ",\"alternates\":[{\"recognizedWords\":\"" + escaped +
                           "\",\"confidence\":0.85}]}";
  m_channel->InvokeMethod("textRecognition",
      std::make_unique<flutter::EncodableValue>(json_result));
}

void SpeechToTextWindowsPlugin::SendError(const std::string& error) {
  if (m_channel) {
    m_channel->InvokeMethod("notifyError",
        std::make_unique<flutter::EncodableValue>(error));
  }
}

void SpeechToTextWindowsPlugin::SendStatus(const std::string& status) {
  if (m_channel) {
    m_channel->InvokeMethod("notifyStatus",
        std::make_unique<flutter::EncodableValue>(status));
  }
}

}  // namespace speech_to_text_windows

// C API export for Flutter plugin registration  
extern "C" __declspec(dllexport) void SpeechToTextWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  speech_to_text_windows::SpeechToTextWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
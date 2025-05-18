#include <iostream>
#include <string>
#include <fstream>
#include <cstdlib>
#include <windows.h> // Для SAPI
#include "vosk_api.h"
#include <comdef.h>
#include <sapi.h>

// ==== Настройки ====
const std::string MODEL_PATH = "models/vosk-model-small-ru-0.22";
const std::string LLAMA_EXE_PATH = "llama.cpp/main.exe";
const std::string LLAMA_MODEL_PATH = "llama.cpp/models/ggml-tinyllama-1.1b-chat-v0.Q5_K_M.gguf";

// ==== Голос ====
void speak(const std::string& text) {
    ISpVoice* pVoice = nullptr;
    CoInitialize(nullptr);
    HRESULT hr = CoCreateInstance(CLSID_SpVoice, NULL, CLSCTX_ALL, IID_ISpVoice, (void**)&pVoice);
    if (SUCCEEDED(hr)) {
        std::wstring wideText = std::wstring(text.begin(), text.end());
        pVoice->Speak(wideText.c_str(), SPF_DEFAULT, NULL);
        pVoice->Release();
    }
    CoUninitialize();
}

// ==== Vosk (распознавание речи) ====
std::string listen_vosk() {
    if (!vosk_model_exist(MODEL_PATH.c_str())) {
        std::cerr << "Модель Vosk не найдена: " << MODEL_PATH << std::endl;
        exit(1);
    }

    VoskModel* model = vosk_model_new(MODEL_PATH.c_str());
    VoskRecognizer* rec = vosk_recognizer_new(model, 16000.0);

    std::cout << "Готов к работе... Слушаю." << std::endl;

    PaStreamParameters inputParameters;
    PaStream* stream;
    PaError err;

    err = Pa_Initialize();
    if (err != paNoError) {
        std::cerr << "PortAudio error: " << Pa_GetErrorText(err) << std::endl;
        return "";
    }

    inputParameters.device = Pa_GetDefaultInputDevice();
    if (inputParameters.device == paNoDevice) {
        std::cerr << "Нет доступного микрофона." << std::endl;
        return "";
    }
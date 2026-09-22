#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <cmath>
#include <cstring>
#include <iostream>

struct ToneState {
    double phase = 0.0;
    double step = 2.0 * 3.141592653589793 * 440.0 / 48000.0;
};

void SDLCALL AudioCallback(void* userdata, Uint8* stream, int len) {
    auto* tone = static_cast<ToneState*>(userdata);
    std::memset(stream, 0, static_cast<size_t>(len));
    auto* out = reinterpret_cast<int16_t*>(stream);
    int sampleCount = len / static_cast<int>(sizeof(int16_t));
    for (int i = 0; i < sampleCount; ++i) {
        out[i] = static_cast<int16_t>(std::sin(tone->phase) * 2000.0);
        tone->phase += tone->step;
        if (tone->phase > 2.0 * 3.141592653589793) {
            tone->phase -= 2.0 * 3.141592653589793;
        }
    }
}

int main() {
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_AUDIO) != 0) {
        std::cerr << SDL_GetError() << '\n';
        return 1;
    }

    ToneState tone{};
    SDL_AudioSpec desired{};
    desired.freq = 48000;
    desired.format = AUDIO_S16SYS;
    desired.channels = 1;
    desired.samples = 1024;
    desired.callback = AudioCallback;
    desired.userdata = &tone;

    SDL_AudioSpec obtained{};
    // requested vs obtained：驱动有权改 freq/channels/samples，
    // 回调里必须按 obtained 的参数算，不能假定 desired 被原样接受。
    SDL_AudioDeviceID dev = SDL_OpenAudioDevice(nullptr, 0, &desired, &obtained, 0);
    if (dev == 0) {
        std::cerr << SDL_GetError() << '\n';
        SDL_Quit();
        return 1;
    }

    std::cout << "==== 08 开始 ====\n";
    std::cout << "deviceOpened=" << (dev > 0)
              << ", freq=" << obtained.freq
              << ", channels=" << static_cast<int>(obtained.channels)
              << ", samples=" << obtained.samples << '\n';
    std::cout << "==== 08 结束 ====\n";
    // 设备名取决于机器接了什么声卡，只做观测，不参与字节比对。
    std::cout << "[观测] 默认输出设备: " << SDL_GetAudioDeviceName(0, 0) << '\n';

    SDL_CloseAudioDevice(dev);
    SDL_Quit();
    return 0;
}


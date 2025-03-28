#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

#include <windows.h>
#include <shellapi.h> // Needed for CommandLineToArgvW

// --- Configuration ---
const wchar_t WINDOW_TITLE[] = L"---BlackOverlayScreen---";
const wchar_t CLASS_NAME[]   = L"BlackOverlayClass";
// --- End Configuration ---

// Forward declaration for wWinMain if WinMain calls it
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow);

// ADDED ANSI WinMain entry point wrapper
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // Get command line arguments as Unicode
    int argc;
    LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (argv == NULL) {
        // Handle error if needed, perhaps return a failure code
        return -1;
    }

    // Call the Unicode wWinMain function
    // Note: We don't directly use lpCmdLine here, relying on GetCommandLineW instead.
    // We also pass the original hInstance and nCmdShow. hPrevInstance is obsolete.
    int result = wWinMain(hInstance, hPrevInstance, NULL, nCmdShow); // Pass NULL for pwCmdLine as wWinMain doesn't use it

    // Free the memory allocated by CommandLineToArgvW
    LocalFree(argv);

    return result;
}


// Window Procedure (remains the same)
LRESULT CALLBACK WndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        case WM_ERASEBKGND:
            return 1;

        case WM_PAINT:
            {
                PAINTSTRUCT ps;
                HDC hdc = BeginPaint(hwnd, &ps);
                FillRect(hdc, &ps.rcPaint, (HBRUSH)GetStockObject(BLACK_BRUSH));
                EndPaint(hwnd, &ps);
            }
            return 0;
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

// Existing UNICODE wWinMain entry point (remains mostly the same)
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow) {
    // NOTE: We ignore hPrevInstance and pCmdLine parameters as they are handled/obsolete

    // 1. Register the window class.
    WNDCLASS wc = { };
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = CLASS_NAME;
    wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);

    if (!RegisterClass(&wc)) {
        return -1;
    }

    // 2. Get screen dimensions for maximization
    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);

    // 3. Create the window.
    HWND hwnd = CreateWindowEx(
        WS_EX_TOPMOST,
        CLASS_NAME,
        WINDOW_TITLE,
        WS_POPUP | WS_VISIBLE,
        0, 0, screenWidth, screenHeight,
        NULL, NULL, hInstance, NULL
    );

    if (hwnd == NULL) {
        return -1;
    }

    // 4. Run the message loop.
    MSG msg = { };
    while (GetMessage(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return (int)msg.wParam;
}
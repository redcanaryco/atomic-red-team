// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"
#include <fstream>
#include <iostream>

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}

SERVICE_STATUS_HANDLE SvcStatusH;

//Initialize Service_Status Structure serviceType and CurrentState values
SERVICE_STATUS SvcStatusS =
{
    //dwServiceType
    SERVICE_WIN32_SHARE_PROCESS,
    //dwCurrentState
    SERVICE_START_PENDING,
    //dwControlsAccepted
    SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN | SERVICE_ACCEPT_PAUSE_CONTINUE
};


DWORD WINAPI SvcCtrlHandler(
    DWORD dwControl,
    DWORD dwEventType,
    LPVOID lpEventData,
    LPVOID lpContext
)
{
    // Handle the requested control code. 

    switch (dwControl)
    {
    case SERVICE_CONTROL_STOP: //Notifies Service it should stop. Should only return "NO_ERROR". Same action as Service Control Shutdown
    case SERVICE_CONTROL_SHUTDOWN: //Notifies a service that the system is shutting down so the service can perform cleanup tasks.
        //Manually set state to "SERVICE_STOPPED" After cleanup commands are run (none in this case)
        SvcStatusS.dwCurrentState = SERVICE_STOPPED;
        break;
    case SERVICE_CONTROL_PAUSE: //Notifies a service that it should pause. 
        SvcStatusS.dwCurrentState = SERVICE_PAUSED;
        break;
    case SERVICE_CONTROL_CONTINUE://Notifies a service that it should Continue after pause.
        SvcStatusS.dwCurrentState = SERVICE_RUNNING;
        break;
    case SERVICE_CONTROL_INTERROGATE:
        break;
    default:
        break;
    };

    SetServiceStatus(SvcStatusH, &SvcStatusS);

    return NO_ERROR;
}

VOID main_payload() {
    using namespace std;
    ofstream myfile;
    myfile.open("C:\\ART_W64Time.txt");
    myfile << "Hello from the Atomic Red Team.\n";
    myfile.close();
    return;
}

extern "C" __declspec(dllexport) VOID WINAPI ServiceMain(DWORD dwArgc, LPCWSTR * lpszArgv)
{

    SvcStatusH = RegisterServiceCtrlHandlerEx(
        L"W64Time",
        SvcCtrlHandler,
        nullptr
    );

    if (!SvcStatusH)
    {
        return;
    }
    // Report initial status to the SCM

    SvcStatusS.dwCurrentState = SERVICE_RUNNING;

    SetServiceStatus(SvcStatusH, &SvcStatusS);
    main_payload();

}

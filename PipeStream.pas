unit PipeStream;

interface

uses Classes, Windows;

type
  TPipeStream = class(THandleStream)
  private
    fhRead  : THandle;
    fhWrite : THandle;
  protected
  public
    constructor Create;
    destructor Destroy; override;

    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;

    property ReadHandle : THandle read fhRead write fhRead;
    property WriteHandle : THandle read fhWrite write fhWrite;
  end;

function RunProcess(FileName, CommandLine: string; var tmpStdIn, tmpStdOut: TPipeStream) : Ansistring;

implementation

function RunProcess(FileName, CommandLine: string; var tmpStdIn, tmpStdOut: TPipeStream) : Ansistring;
var
  SI        : TStartupInfo;
  PI        : TProcessInformation;
  //TmpBuf    : PChar;
begin
  Result := '';
  GetStartupInfo(SI);
  tmpStdIn  := TPipeStream.Create;
  tmpStdOut := TPipeStream.Create;
  SI.hStdInput := tmpStdIn.ReadHandle;
  SI.hStdOutput := tmpStdOut.WriteHandle;
  SI.hStdError := tmpStdOut.WriteHandle;
  SI.dwFlags := SI.dwFlags or STARTF_USESTDHANDLES;
  CreateProcess(PChar(FileName), PChar(CommandLine), nil, nil, true,
    DETACHED_PROCESS or CREATE_SUSPENDED, nil, nil, SI, PI);
  //GetMem(TmpBuf, 4096);

  ResumeThread(PI.hThread);
  {repeat
    GetExitCodeProcess(PI.hProcess, TmpCode);
    repeat
      PeekNamedPipe(tmpStdOut.ReadHandle, nil, 0, nil,
        @NumRead, nil);
      if NumRead > 0 then
      begin
        NumRead := tmpStdOut.Read(TmpBuf^, 4096);
        SetString(TmpStr, TmpBuf, NumRead);
        Result := Result + TmpStr;
      end;
    until NumRead = 0;
    Sleep(0);
  until TmpCode <> STILL_ACTIVE;
  FreeMem(TmpBuf);
  tmpStdIn.Free;
  tmpStdOut.Free;  }
end;

{ TPipeStream }

constructor TPipeStream.Create;
var
  SAPipe  : SECURITY_ATTRIBUTES;
begin
  inherited Create(0);
  FillChar(SAPipe, SizeOf(SAPipe), 0);
  SAPipe.nLength := SizeOf(SAPipe);
  SAPipe.bInheritHandle := true;
  CreatePipe(fhRead, fhWrite, @SAPipe, 0);
end;

destructor TPipeStream.Destroy;
begin
  CloseHandle(fhRead);
  CloseHandle(fhWrite);

  inherited;
end;

function TPipeStream.Read(var Buffer; Count: Integer): Longint;
begin
  FHandle := fhRead;
  Result := inherited Read(Buffer, Count);
  //FHandle := 0;
end;

function TPipeStream.Write(const Buffer; Count: Integer): Longint;
begin
  FHandle := fhWrite;
  Result := inherited Write(Buffer, Count);
  //FHandle := 0;
end;

end.

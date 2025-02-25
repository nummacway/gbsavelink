program GBsavelink;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  PipeStream in 'PipeStream.pas',
  Windows,
  Classes,
  Types,
  MBC in 'MBC.pas';

type
  TReaderThread = class(TThread)
    procedure Execute(); override;
  end;

var
  SI: TStartupInfo;
  PI: TProcessInformation;
  tmpIn, tmpOut: TPipeStream;

  Command, Params: string;

  SB: TStringBuilder;
  CMD: TStringBuilder;
  MBC: TGenericMBC;
  ExitCode: Dword;
  Arr: TArray<Byte>;
  TempCmd: RawByteString;
  Bank: Integer;
  MS: TMemoryStream;

  Thread: TReaderThread;

const
  HeaderRead: AnsiString = 'r 0147 03'#10;
  Prompt = 'Enter command: ';

{ General Features }

function FromHex(const H: string): TArray<Byte>;
var
  H2: string;
  i: Integer;
  Count: Integer;
begin
  H2 := Uppercase(H);
  Count := 0;
  for i := 1 to Length(H2) do
  case H2[i] of
    '0'..'9', 'A'..'F':
      begin
        Inc(Count);
        H2[Count] := H2[i];
      end;
  end;
  SetLength(Result, Count div 2);
  for i := Low(Result) to High(Result) do
  Result[i] := StrToInt('0x' + Copy(H2, i*2+1, 2));
end;

function EndsSB(const str: string): Boolean;
var
  i: Integer;
  j: Integer;
begin
  GetExitCodeProcess(PI.hProcess, ExitCode);
  if ExitCode <> STILL_ACTIVE then
  raise Exception.Create('GBlinkDX died');

  j := SB.Length;
  if Length(str) > j then
  Exit(False);
  for i := Length(str) downto 1 do
  begin
    Dec(j);
    if SB.Chars[j] <> str[i] then
    Exit(False);
  end;
  Result := True;
end;

function GetHex(): TArray<Byte>;
begin
  while not EndsSB(Prompt) do
  Sleep(1);

  SB.Remove(SB.Length - Length(Prompt) - 1, Length(Prompt));
  if SB.Length < 1337 then
  writeln('parsing: ' + SB.ToString());
  Result := FromHex(Trim(SB.ToString()));
  SB.Clear();
end;

{ TReaderThread }

procedure TReaderThread.Execute;
var
  ReadCount: Integer;
  b: Byte;
begin
  while True do
  begin
    PeekNamedPipe(tmpOut.ReadHandle, nil, 0, nil, @ReadCount, nil);

    for ReadCount := ReadCount downto 1 do
    begin
      tmpOut.Read(b, 1);
      SB.Append(Chr(b));
      write(Chr(b));
    end;

    Sleep(1);
  end;
end;

{ Main }

begin
  try
    // Init pipes
    writeln('Starting Pipes...');
    tmpIn := TPipeStream.Create();
    tmpOut := TPipeStream.Create();
    SI.hStdInput := tmpIn.ReadHandle;
    SI.hStdOutput := tmpOut.WriteHandle;
    SI.hStdError := tmpOut.WriteHandle;

    Command := ExtractFilePath(paramstr(0)) + 'gblinkdx.exe';
    Params := 'output.gb -p0378 -q'; // some weird parameter because I just couldn't get gblinkdx to go into quiet mode

    writeln('Preparing process...');
    GetStartupInfo(SI);
    SI.dwFlags := {SI.dwFlags or} STARTF_USESTDHANDLES;
    writeln('Starting process...');
    CreateProcess(PChar(Command), PChar(Params), nil, nil, true,
      DETACHED_PROCESS or CREATE_SUSPENDED, nil, nil, SI, PI);
    ResumeThread(PI.hThread);

    SB := TStringBuilder.Create();

    writeln('Starting thread...');
    Thread := TReaderThread.Create(False);

    try
      while not EndsSB('press enter to continue') do
      Sleep(1);

      SB.Clear();
      writeln('Writing enter...');
      tmpIn.WriteData(Byte(10));

      while not EndsSB(Prompt) do
      Sleep(1);
      SB.Clear();

      writeln('Getting header...');
      tmpIn.Write(HeaderRead[1], Length(HeaderRead));

      writeln('Creating MBC...');
      Arr := Copy(GetHex());
      case Arr[0] of
        $02, $03: MBC := TMBC1.Create(Arr);
        $05, $06: MBC := TMBC2.Create(Arr);
        $10, $12, $13, $1A, $1B, $1D, $1E: MBC := TGenericMBC.Create(Arr);
        else raise Exception.CreateFmt('Unknown MBC $%s @ $0147', [IntToHex(Arr[0], 2)]);
      end;

      writeln('Making command...');
      CMD := TStringBuilder.Create();
      try
        CMD.Append(MBC.GetInitCommand());
        for Bank := 0 to MBC.GetRAMBanks() - 1 do
        begin
          CMD.Append(';').Append(MBC.GetRAMBankSwitchCommand(Bank));
          CMD.Append(';r a000 ff;r a0ff ff;r a1fe ff;r a2fd ff;r a3fc ff;r a4fb ff;r a5fa ff;r a6f9 ff;r a7f8 ff;r a8f7 ff;r a9f6 ff;r aaf5 ff;r abf4 ff;r acf3 ff;r adf2 ff;r aef1 ff;r aff0 ff;r b0ef ff;r b1ee ff;r b2ed ff;r b3ec ff;r b4eb ff;r b5ea ff;r b6e9 ff;r b7e8 ff;r b8e7 ff;r b9e6 ff;r bae5 ff;r bbe4 ff;r bce3 ff;r bde2 ff;r bee1 ff;r bfe0 20');
        end;
        writeln('Writing command...');
        TempCmd := RawByteString(CMD.ToString());
        tmpIn.Write(TempCmd[1], Length(TempCmd));
        tmpIn.WriteData(Byte(10));
      finally
        CMD.Free();
      end;

      writeln('Parsing result...');
      Arr := Copy(GetHex());
      MS := TBytesStream.Create(Arr);
      writeln('Writing result to file...');
      if paramstr(1) = '' then
      MS.SaveToFile('output.sav')
      else
      MS.SaveToFile(paramstr(1));
      writeln('Done.');
    finally
      GetExitCodeProcess(PI.hProcess, ExitCode);
      if ExitCode = STILL_ACTIVE then
      TerminateProcess(PI.hProcess, 0);
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

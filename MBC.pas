unit MBC;

interface

uses
  Types, SysUtils;

type
  TGenericMBC = class
    constructor Create(AHeader: TArray<Byte>); virtual;
    function GetRAMBanks: Integer; virtual;
    function GetInitCommand(): string; virtual;
    function GetRAMBankSwitchCommand(Bank: Integer): string; virtual;
  private
    function GetWriteCommand(Data: TArray<TPoint>): string;
    var
      Header: TArray<Byte>;
  end;

  TMBC1 = class(TGenericMBC)
    function GetInitCommand(): string; override;
  end;

  TMBC2 = class(TGenericMBC)
    function GetRAMBanks: Integer; override;
    function GetRAMBankSwitchCommand(Bank: Integer): string; override;
  end;

implementation

{ TGenericMBC }

constructor TGenericMBC.Create(AHeader: TArray<Byte>);
begin
  Header := Copy(AHeader);
end;

function TGenericMBC.GetInitCommand: string;
begin
  Result := GetWriteCommand([Point($0000, $0a)]);
end;

function TGenericMBC.GetRAMBanks: Integer;
begin
  case Header[2] of
    $00: Exit(0);
    $02: Exit(1);
    $03: Exit(4);
    $04: Exit(16);
    $05: Exit(8);
    else raise Exception.CreateFmt('Unknown RAM bank number $%s', [IntToHex(Header[2], 2)]);
  end;
end;

function TGenericMBC.GetRAMBankSwitchCommand(Bank: Integer): string;
begin
  Result := GetWriteCommand([Point($4000, Bank)]);
end;

function TGenericMBC.GetWriteCommand(Data: TArray<TPoint>): string;
var
  Cmd: TPoint;
begin
  Result := '';
  for Cmd in Data do
  Result := Result + ';w ' + IntToHex(Cmd.X, 4) + ' ' + IntToHex(Cmd.Y, 2);
  Delete(Result, 1, 1);
end;

{ TMBC1 }

function TMBC1.GetInitCommand: string;
begin
  Result := GetWriteCommand([Point($0000, $0a), Point($6000, $01)]);
end;

{ TMBC2 }

function TMBC2.GetRAMBanks: Integer;
begin
  Result := 1;
end;

function TMBC2.GetRAMBankSwitchCommand(Bank: Integer): string;
begin
  // do nothing
end;

end.

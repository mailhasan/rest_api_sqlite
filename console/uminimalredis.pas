unit uMinimalRedis;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Sockets;

type
  TMinimalRedisClient = class
  private
    FSocket: TSocket;
    FConnected: Boolean;
    FHost: string;
    FPort: Integer;
    procedure KirimPerintah(const ACommand: string);
    function BacaRespons: string;
  public
    constructor Create(const AHost: string = '127.0.0.1'; APort: Integer = 6379);
    destructor Destroy; override;
    function Connect: Boolean;
    procedure Disconnect;
    function SetKey(const AKey, AValue: string): Boolean;
    function SetKeyEx(const AKey: string; ASeconds: Integer; const AValue: string): Boolean;
    function GetKey(const AKey: string): string;
    function DelKey(const AKey: string): Boolean;
    property Connected: Boolean read FConnected;
  end;

implementation

constructor TMinimalRedisClient.Create(const AHost: string; APort: Integer);
begin
  FHost := AHost;
  FPort := APort;
  FConnected := False;
end;

destructor TMinimalRedisClient.Destroy;
begin
  Disconnect;
  inherited Destroy;
end;

function TMinimalRedisClient.Connect: Boolean;
var
  vAddr: TInetSockAddr;
begin
  if FConnected then begin Result := True; Exit; end;

  FSocket := fpsocket(AF_INET, SOCK_STREAM, 0);
  if FSocket = -1 then begin Result := False; Exit; end;

  vAddr.sin_family := AF_INET;
  vAddr.sin_port := htons(FPort);
  vAddr.sin_addr := StrToNetAddr(FHost);

  if fpconnect(FSocket, @vAddr, SizeOf(vAddr)) = 0 then
    FConnected := True
  else
    FConnected := False;

  Result := FConnected;
end;

procedure TMinimalRedisClient.Disconnect;
begin
  if FConnected then
  begin
    CloseSocket(FSocket);
    FConnected := False;
  end;
end;

procedure TMinimalRedisClient.KirimPerintah(const ACommand: string);
begin
  if FConnected then
    fpsend(FSocket, @ACommand[1], Length(ACommand), 0);
end;

function TMinimalRedisClient.BacaRespons: string;
var
  vBuffer: array[0..2047] of Char;
  vLen: Integer;
begin
  Result := '';
  FillChar(vBuffer, SizeOf(vBuffer), 0);
  vLen := fprecv(FSocket, @vBuffer, SizeOf(vBuffer) - 1, 0);
  if vLen > 0 then
    Result := StrPas(vBuffer);
end;

function TMinimalRedisClient.SetKey(const AKey, AValue: string): Boolean;
var
  vCmd: string;
begin
  // RESP Protocol format untuk perintah Redis: SET key value
  vCmd := '*3' + #13#10 +
          '$3' + #13#10 + 'SET' + #13#10 +
          '$' + IntToStr(Length(AKey)) + #13#10 + AKey + #13#10 +
          '$' + IntToStr(Length(AValue)) + #13#10 + AValue + #13#10;
  KirimPerintah(vCmd);
  Result := Pos('+OK', BacaRespons) > 0;
end;

function TMinimalRedisClient.SetKeyEx(const AKey: string; ASeconds: Integer; const AValue: string): Boolean;
var
  vCmd: string;
  vSecStr: string;
begin
  vSecStr := IntToStr(ASeconds);
  // RESP Protocol format untuk perintah Redis: SET key value EX seconds
  vCmd := '*5' + #13#10 +
          '$3' + #13#10 + 'SET' + #13#10 +
          '$' + IntToStr(Length(AKey)) + #13#10 + AKey + #13#10 +
          '$' + IntToStr(Length(AValue)) + #13#10 + AValue + #13#10 +
          '$2' + #13#10 + 'EX' + #13#10 +
          '$' + IntToStr(Length(vSecStr)) + #13#10 + vSecStr + #13#10;
  KirimPerintah(vCmd);
  Result := Pos('+OK', BacaRespons) > 0;
end;

function TMinimalRedisClient.GetKey(const AKey: string): string;
var
  vCmd, vResp: string;
  vLines: TStringList;
begin
  Result := '';
  vCmd := '*2' + #13#10 +
          '$3' + #13#10 + 'GET' + #13#10 +
          '$' + IntToStr(Length(AKey)) + #13#10 + AKey + #13#10;
  KirimPerintah(vCmd);
  vResp := BacaRespons;

  if (vResp <> '') and (vResp[1] = '$') then
  begin
    if Pos('$-1', vResp) = 1 then Exit; // Key tidak ditemukan / nil

    vLines := TStringList.Create;
    try
      vLines.Text := vResp;
      if vLines.Count > 2 then
        Result := vLines.Strings[1]; // Mengambil baris data payload JSON-nya
    finally
      vLines.Free;
    end;
  end;
end;

function TMinimalRedisClient.DelKey(const AKey: string): Boolean;
var
  vCmd: string;
begin
  vCmd := '*2' + #13#10 +
          '$3' + #13#10 + 'DEL' + #13#10 +
          '$' + IntToStr(Length(AKey)) + #13#10 + AKey + #13#10;
  KirimPerintah(vCmd);
  Result := Pos(':1', BacaRespons) > 0;
end;

end.


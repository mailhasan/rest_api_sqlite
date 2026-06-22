unit uhandlerapi;

{$MODE DELPHI} // Menggunakan mode Delphi sesuai contoh resmi

interface

uses
  SysUtils, Classes, ZDataset, ZConnection, BrookURLRouter,
  BrookHTTPRequest, BrookHTTPResponse, BrookUtility, fpjson, jsonparser,
  zstream, uMinimalRedis;

// Kelas Rute Registrasi Utama
type
  TRouteHome = class(TBrookURLRoute)
  protected
    procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  public
    procedure AfterConstruction; override;
  end;

  TRouteBarangCRUD = class(TBrookURLRoute)
  protected
    procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  public
    procedure AfterConstruction; override;
  end;

  TRouteGetToken = class(TBrookURLRoute)
  protected
    procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  public
    procedure AfterConstruction; override;
  end;

  TRouteBarangKompres = class(TBrookURLRoute)
  protected
    procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  public
    procedure AfterConstruction; override;
  end;

  TRouteBarangLimit = class(TBrookURLRoute)
  protected
    procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  public
    procedure AfterConstruction; override;
  end;

  TRouteBarangCache = class(TBrookURLRoute)
  protected
    procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  public
    procedure AfterConstruction; override;
  end;

procedure RegistrasiSemuaRute(ARoutesCollection: TCollection; AZConn: TZConnection; AIPTracker: TStringList);

implementation

var
  gZConn: TZConnection;
  gIPTracker: TStringList;

procedure RegistrasiSemuaRute(ARoutesCollection: TCollection; AZConn: TZConnection; AIPTracker: TStringList);
begin
  gZConn := AZConn;
  gIPTracker := AIPTracker;

  // Membuat instance class rute ke dalam koleksi routes milik router sesuai petunjuk TServer resmi
  TRouteHome.Create(ARoutesCollection);
  TRouteBarangCRUD.Create(ARoutesCollection);
  TRouteGetToken.Create(ARoutesCollection);
  TRouteBarangKompres.Create(ARoutesCollection);
  TRouteBarangLimit.Create(ARoutesCollection);
  TRouteBarangCache.Create(ARoutesCollection);
end;

// ----------------=================================================
// SHARED SYSTEM MIDDLEWARES & HELPERS
// ----------------=================================================

function IsAuthenticatedtoken(ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse): Boolean;
var
  vToken: string;
  vQueryUser: TZQuery;
begin
  Result := False;
  vToken := ARequest.Headers.Values['Authorization'];
  if vToken = '' then
  begin
    AResponse.Send('{"error": "Token missing"}', 'application/json', 401);
    Exit;
  end;
  vQueryUser := TZQuery.Create(nil);
  try
    vQueryUser.Connection := gZConn;
    vQueryUser.SQL.Text := 'SELECT id_user FROM users WHERE token = :token LIMIT 1';
    vQueryUser.ParamByName('token').AsString := vToken;
    vQueryUser.Open;
    if not vQueryUser.IsEmpty then Result := True else AResponse.Send('{"error": "Token invalid"}', 'application/json', 401);
  finally
    vQueryUser.Free;
  end;
end;

function CheckRateLimit(AIP: string): Boolean;
var
  vIndex, vHitCount: Integer; vCurrentTime, vLastResetTime: TDateTime; vDataStr, vHitStr, vTimeStr: string; vPosPemisah: Integer;
begin
  Result := True; vCurrentTime := Now; vIndex := gIPTracker.IndexOfName(AIP);
  if vIndex = -1 then gIPTracker.Add(AIP + '=1|' + DateTimeToStr(vCurrentTime + (1 / 1440)))
  else begin
    vDataStr := gIPTracker.ValueFromIndex[vIndex]; vPosPemisah := Pos('|', vDataStr);
    vHitStr := Copy(vDataStr, 1, vPosPemisah - 1); vTimeStr := Copy(vDataStr, vPosPemisah + 1, Length(vDataStr));
    vHitCount := StrToIntDef(vHitStr, 0); vLastResetTime := StrToDateTimeDef(vTimeStr, vCurrentTime);
    if vCurrentTime > vLastResetTime then gIPTracker.Strings[vIndex] := AIP + '=1|' + DateTimeToStr(vCurrentTime + (1 / 1440))
    else begin
      Inc(vHitCount); if vHitCount > 10 then Result := False;
      gIPTracker.Strings[vIndex] := AIP + '=' + IntToStr(vHitCount) + '|' + DateTimeToStr(vLastResetTime);
    end;
  end;
end;

function KompresStringKeGZip(const AInput: string): string;
var
  vStreamInput, vStreamOutput: TStringStream; vKompresor: TCompressionStream;
begin
  Result := ''; if AInput = '' then Exit;
  vStreamInput := TStringStream.Create(AInput); vStreamOutput := TStringStream.Create('');
  vKompresor := TCompressionStream.Create(cldefault, vStreamOutput);
  try vKompresor.CopyFrom(vStreamInput, vStreamInput.Size); vKompresor.Free; Result := vStreamOutput.DataString;
  finally vStreamInput.Free; vStreamOutput.Free; end;
end;

// ----------------=================================================
// IMPLEMENTASI CLASS ROUTE METHODS
// ----------------=================================================

{ TRouteHome }
procedure TRouteHome.AfterConstruction;
begin
  inherited AfterConstruction; // Wajib panggil inherited di Tardigrade
  Methods := [rmGET];
  Pattern := '/';
end;

procedure TRouteHome.DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
  AResponse.Send('<html><body><h3>Home Page - Class Based Console</h3></body></html>', 'text/html', 200);
end;

{ TRouteBarangCRUD }
procedure TRouteBarangCRUD.AfterConstruction;
begin
  inherited AfterConstruction;
  // Wajib masukkan semua method ini agar bisa melayani GET, POST, PUT, dan DELETE
  Methods := [rmGET, rmPOST, rmPUT, rmDELETE];
  Pattern := '/produk';
end;

procedure TRouteBarangCRUD.DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
  vNama, vKode: string;
  JSONData: TJSONData;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  vQuery: TZQuery;
begin
  if not IsAuthenticatedtoken(ARequest, AResponse) then Exit;

  vQuery := TZQuery.Create(nil);
  vQuery.Connection := gZConn;
  try
    // --- METHOD: POST (TAMBAH DATA) ---
    if ARequest.Method = 'POST' then
    begin
      try
        vNama := ARequest.Payload.ToString;
        JSONData := GetJSON(vNama); JSONObject := TJSONObject(JSONData);
        vQuery.SQL.Text := 'INSERT INTO barang (nama_barang, kategori, harga, stok, id_user_admin) VALUES (:nama, :kategori, :harga, :stok, :user)';
        vQuery.ParamByName('nama').AsString := JSONObject.Get('nama', '');
        vQuery.ParamByName('kategori').AsString := JSONObject.Get('kategori', 'Umum');
        vQuery.ParamByName('harga').AsFloat := JSONObject.Get('harga', 0.0);
        vQuery.ParamByName('stok').AsInteger := JSONObject.Get('stok', 0);
        vQuery.ParamByName('user').AsInteger := JSONObject.Get('id_user', 1);
        vQuery.ExecSQL;
        AResponse.Send('{"status": "success"}', 'application/json', 201);
      except
        on E: Exception do AResponse.SendFmt('{"status": "error", "message": "%s"}', [E.Message], 'application/json', 500);
      end;
      if Assigned(JSONData) then JSONData.Free;
    end

    // --- METHOD: PUT (UPDATE DATA) ---
    else if ARequest.Method = 'PUT' then
    begin
      try
        vNama := ARequest.Payload.ToString;
        JSONData := GetJSON(vNama); JSONObject := TJSONObject(JSONData);
        vQuery.SQL.Text := 'UPDATE barang SET nama_barang = :nama, kategori = :kategori, harga = :harga, stok = :stok WHERE id_barang = :id';
        vQuery.ParamByName('id').AsInteger := JSONObject.Get('id', 0);
        vQuery.ParamByName('nama').AsString := JSONObject.Get('nama', '');
        vQuery.ParamByName('kategori').AsString := JSONObject.Get('kategori', 'Umum');
        vQuery.ParamByName('harga').AsFloat := JSONObject.Get('harga', 0.0);
        vQuery.ParamByName('stok').AsInteger := JSONObject.Get('stok', 0);
        vQuery.ExecSQL;
        AResponse.Send('{"status": "success", "message": "Data berhasil diperbarui"}', 'application/json', 200);
      except
        on E: Exception do AResponse.SendFmt('{"status": "error", "message": "%s"}', [E.Message], 'application/json', 500);
      end;
      if Assigned(JSONData) then JSONData.Free;
    end

    // --- METHOD: DELETE (HAPUS DATA VIA ?id=...) ---
    else if ARequest.Method = 'DELETE' then
    begin
      try
        vKode := ARequest.Params.Values['id'];
        if vKode = '' then raise Exception.Create('ID barang harus disertakan (gunakan ?id=...)');

        vQuery.SQL.Text := 'DELETE FROM barang WHERE id_barang = :id';
        vQuery.ParamByName('id').AsInteger := StrToIntDef(vKode, 0);
        vQuery.ExecSQL;

        AResponse.Send('{"status": "success", "message": "Data dengan ID ' + vKode + ' berhasil dihapus"}', 'application/json', 200);
      except
        on E: Exception do AResponse.SendFmt('{"status": "error", "message": "%s"}', [E.Message], 'application/json', 500);
      end;
    end

    // --- METHOD: GET (READ / PENCARIAN DATA) ---
    else if ARequest.Method = 'GET' then
    begin
      vNama := ARequest.Params.Values['nama'];
      vKode := ARequest.Params.Values['kode'];
      JSONArray := TJSONArray.Create;
      try
        vQuery.SQL.Clear;
        vQuery.SQL.Add('SELECT id_barang, nama_barang, harga, stok FROM barang WHERE 1=1');

        if vKode <> '' then
        begin
          vQuery.SQL.Add('AND id_barang = :kode');
          vQuery.ParamByName('kode').AsString := vKode;
        end;

        if vNama <> '' then
        begin
          vQuery.SQL.Add('AND nama_barang LIKE :nama');
          vQuery.ParamByName('nama').AsString := '%' + vNama + '%';
        end;

        vQuery.SQL.Add('LIMIT 100');
        vQuery.Open;

        while not vQuery.EOF do
        begin
          JSONObject := TJSONObject.Create;
          JSONObject.Add('id', vQuery.FieldByName('id_barang').AsInteger);
          JSONObject.Add('nama', vQuery.FieldByName('nama_barang').AsString);
          JSONObject.Add('harga', vQuery.FieldByName('harga').AsFloat);
          JSONObject.Add('stok', vQuery.FieldByName('stok').AsInteger);
          JSONArray.Add(JSONObject);
          vQuery.Next;
        end;

        AResponse.Send(JSONArray.AsJSON, 'application/json; charset=utf-8', 200);
      finally
        vQuery.Close;
        JSONArray.Free;
      end;
    end;

  finally
    vQuery.Free;
  end;
end;

{ TRouteGetToken }
procedure TRouteGetToken.AfterConstruction;
begin
  inherited AfterConstruction;
  Methods := [rmPOST];
  Pattern := '/login'; // Ini rute login Anda yang sudah sukses
end;

procedure TRouteGetToken.DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
  JSONData: TJSONData; JSONObject, JSONRes: TJSONObject; vUser, vPass, vToken: string; vID: Integer; vQuery: TZQuery;
begin
  vQuery := TZQuery.Create(nil); vQuery.Connection := gZConn;
  try
    JSONData := GetJSON(ARequest.Payload.ToString); JSONObject := TJSONObject(JSONData);
    vUser := JSONObject.Get('username', ''); vPass := JSONObject.Get('password', '');
    vQuery.SQL.Text := 'SELECT id_user FROM users WHERE username = :user AND password = :pass';
    vQuery.ParamByName('user').AsString := vUser; vQuery.ParamByName('pass').AsString := vPass; vQuery.Open;
    if not vQuery.IsEmpty then
    begin
      vID := vQuery.FieldByName('id_user').AsInteger;
      vToken := Brook.SHA1(TGUID.NewGuid.ToString + vUser + DateTimeToStr(Now));
      vQuery.Close;
      vQuery.SQL.Text := 'UPDATE users SET token = :token WHERE id_user = :id';
      vQuery.ParamByName('token').AsString := vToken; vQuery.ParamByName('id').AsInteger := vID; vQuery.ExecSQL;
      JSONRes := TJSONObject.Create;
      try
        JSONRes.Add('status', 'success'); JSONRes.Add('token', vToken);
        AResponse.Send(JSONRes.AsJSON, 'application/json', 200);
      finally JSONRes.Free; end;
    end else AResponse.Send('{"status": "error"}', 'application/json', 401);
  finally JSONData.Free; vQuery.Free; end;
end;

{ TRouteBarangKompres }
procedure TRouteBarangKompres.AfterConstruction;
begin
  inherited AfterConstruction;
  Methods := [rmGET];
  Pattern := '/barang_kompres';
end;

procedure TRouteBarangKompres.DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
  vJSON, vJSONKompres: string; JSONArray: TJSONArray; JSONObject: TJSONObject; vQuery: TZQuery;
begin
  if not IsAuthenticatedtoken(ARequest, AResponse) then Exit;
  JSONArray := TJSONArray.Create; vQuery := TZQuery.Create(nil);
  try
    vQuery.Connection := gZConn; vQuery.SQL.Add('SELECT id_barang, nama_barang FROM barang LIMIT 500'); vQuery.Open;
    while not vQuery.EOF do begin
      JSONObject := TJSONObject.Create;
      JSONObject.Add('id', vQuery.FieldByName('id_barang').AsInteger);
      JSONObject.Add('nama', vQuery.FieldByName('nama_barang').AsString);
      JSONArray.Add(JSONObject); vQuery.Next;
    end;
    vJSON := JSONArray.AsJSON; vJSONKompres := KompresStringKeGZip(vJSON);
    AResponse.Headers.Add('Content-Encoding', 'deflate');
    AResponse.Send(vJSONKompres, 'application/json; charset=utf-8', 200);
  finally vQuery.Free; JSONArray.Free; end;
end;

{ TRouteBarangLimit }
procedure TRouteBarangLimit.AfterConstruction;
begin
  inherited AfterConstruction;
  Methods := [rmGET];
  Pattern := '/barang_limit';
end;

procedure TRouteBarangLimit.DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
  vClientIP: string; JSONArray: TJSONArray; JSONObject: TJSONObject; vQuery: TZQuery;
begin
  vClientIP := ARequest.IP; if vClientIP = '' then vClientIP := '127.0.0.1';
  if not CheckRateLimit(vClientIP) then begin
    AResponse.Headers.Add('Retry-After', '60');
    AResponse.Send('{"status": "error", "message": "Too Many Requests!"}', 'application/json', 429);
    Exit;
  end;
  if not IsAuthenticatedtoken(ARequest, AResponse) then Exit;
  JSONArray := TJSONArray.Create; vQuery := TZQuery.Create(nil);
  try
    vQuery.Connection := gZConn; vQuery.SQL.Add('SELECT id_barang, nama_barang FROM barang LIMIT 10'); vQuery.Open;
    while not vQuery.EOF do begin
      JSONObject := TJSONObject.Create; JSONObject.Add('nama', vQuery.FieldByName('nama_barang').AsString);
      JSONArray.Add(JSONObject); vQuery.Next;
    end;
    AResponse.Send(JSONArray.AsJSON, 'application/json; charset=utf-8', 200);
  finally vQuery.Free; JSONArray.Free; end;
end;

{ TRouteBarangCache }
procedure TRouteBarangCache.AfterConstruction;
begin
  inherited AfterConstruction;
  Methods := [rmGET];
  Pattern := '/barang_cache';
end;

procedure TRouteBarangCache.DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
  vNamaParam, vJSON, vCacheKey: string; vRedis: TMinimalRedisClient; vQuery: TZQuery; JSONArray: TJSONArray; JSONObject: TJSONObject;
begin
  if not IsAuthenticatedtoken(ARequest, AResponse) then Exit;
  vNamaParam := Trim(ARequest.Params.Values['nama']);
  vCacheKey := 'cache:barang:n_' + LowerCase(vNamaParam);
  vRedis := TMinimalRedisClient.Create('127.0.0.1', 6379);
  try
    try if vRedis.Connect then vJSON := vRedis.GetKey(vCacheKey); except vJSON := ''; end;
    if vJSON <> '' then begin
      AResponse.Headers.Add('X-Cache', 'HIT'); AResponse.Send(vJSON, 'application/json', 200); Exit;
    end;
    JSONArray := TJSONArray.Create; vQuery := TZQuery.Create(nil);
    try
      vQuery.Connection := gZConn; vQuery.SQL.Add('SELECT id_barang, nama_barang FROM barang LIMIT 100'); vQuery.Open;
      while not vQuery.EOF do begin
        JSONObject := TJSONObject.Create; JSONObject.Add('nama', vQuery.FieldByName('nama_barang').AsString);
        JSONArray.Add(JSONObject); vQuery.Next;
      end;
      vJSON := JSONArray.AsJSON; if vRedis.Connected then vRedis.SetKeyEx(vCacheKey, 300, vJSON);
      AResponse.Headers.Add('X-Cache', 'MISS'); AResponse.Send(vJSON, 'application/json', 200);
    finally vQuery.Free; JSONArray.Free; end;
  finally vRedis.Free; end;
end;

end.

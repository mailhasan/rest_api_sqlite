unit unitUtama;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, Forms, Controls, Graphics, Dialogs,
  Spin, LCLIntf, StdCtrls, ActnList, ZDataset, ZConnection, BrookHTTPServer,
  BrookURLRouter, BrookHTTPResponse, BrookHTTPRequest, BrookUtility, fpjson,
  jsonparser;

type

  { TFormUtama }

  TFormUtama = class(TForm)
    acStart: TAction;
    acStop: TAction;
    alMain: TActionList;
    BrookHTTPServer1: TBrookHTTPServer;
    BrookURLRouter1: TBrookURLRouter;
    btStart: TButton;
    btStop: TButton;
    edPort: TSpinEdit;
    lbLink: TLabel;
    lbPort: TLabel;
    SQLTransactionUser: TSQLTransaction;
    SQLTransactionBarang: TSQLTransaction;
    ZConnectiondb: TZConnection;
    SQLQueryUser: TZQuery;
    SQLQueryBarang: TZQuery;
    procedure acStartExecute(Sender: TObject);
    procedure acStopExecute(Sender: TObject);
    procedure BrookHTTPServer1Error(ASender: TObject; AException: Exception);
    procedure BrookHTTPServer1Request(ASender: TObject;
      ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
    procedure BrookHTTPServer1RequestError(ASender: TObject;
      ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse;
      AException: Exception);
    procedure BrookHTTPServer1Start(Sender: TObject);
    procedure BrookHTTPServer1Stop(Sender: TObject);
    procedure BrookURLRouter1Routes0Request(ASender: TObject;
      ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
      AResponse: TBrookHTTPResponse);
    procedure BrookURLRouter1Routes1Request(ASender: TObject;
      ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
      AResponse: TBrookHTTPResponse);
    procedure BrookURLRouter1Routes2Request(ASender: TObject;
      ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
      AResponse: TBrookHTTPResponse);
    procedure BrookURLRouter1Routes2RequestMethod(ASender: TObject;
      ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
      AResponse: TBrookHTTPResponse; var AAllowed: Boolean);
    procedure BrookURLRouter1Routes3Request(ASender: TObject;
      ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
      AResponse: TBrookHTTPResponse);
    procedure edPortChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbLinkClick(Sender: TObject);
    procedure lbLinkMouseEnter(Sender: TObject);
    procedure lbLinkMouseLeave(Sender: TObject);
    procedure ZConnection1AfterReconnect(Sender: TObject);
  private
   function IsAuthenticated(ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse): Boolean;
   function IsAuthenticatedtoken(ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse): Boolean;
  public
   procedure UpdateControls; {$IFNDEF DEBUG}inline;{$ENDIF}
  end;

var
  FormUtama: TFormUtama;

implementation

{$R *.lfm}

///Cek Auth simpel
function TFormUtama.IsAuthenticated(ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse): Boolean;
var
  vToken: string;
begin
  Result := False;
  vToken := ARequest.Headers.Values['Authorization'];

  if (vToken <> '') and (vToken = 'ismail') then
  begin
    Result := True;
  end
  else
  begin
    AResponse.Send('{"status": "error", "message": "Unauthorized: Token tidak valid atau absen"}',
      'application/json', 401);
  end;
end;

///Cek Auth db tabel token
function TFormUtama.IsAuthenticatedtoken(ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse): Boolean;
var
  vToken: string;
begin
  Result := False;
  vToken := ARequest.Headers.Values['Authorization'];

  if vToken = '' then
  begin
    AResponse.Send('{"error": "Token missing"}', 'application/json', 401);
    Exit;
  end;

  try
    if not ZConnectiondb.Connected then ZConnectiondb.Connect;

    SQLQueryUser.Close;
    SQLQueryUser.SQL.Text := 'SELECT id_user FROM users WHERE token = :token LIMIT 1';
    SQLQueryUser.ParamByName('token').AsString := vToken;
    SQLQueryUser.Open;

    // Cek apakah data token ditemukan
    if not SQLQueryUser.IsEmpty then
      Result := True
    else
      AResponse.Send('{"error": "Token invalid"}', 'application/json', 401);

  finally
    SQLQueryUser.Close;
  end;
end;

procedure TFormUtama.acStartExecute(Sender: TObject);
begin
  BrookURLRouter1.Open;
  BrookHTTPServer1.Open;
end;

procedure TFormUtama.acStopExecute(Sender: TObject);
begin
  BrookHTTPServer1.Close;
end;

procedure TFormUtama.BrookHTTPServer1Error(ASender: TObject;
  AException: Exception);
begin

end;

procedure TFormUtama.BrookHTTPServer1Request(ASender: TObject;
  ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
   BrookURLRouter1.Route(ASender, ARequest, AResponse);
end;

procedure TFormUtama.BrookHTTPServer1RequestError(ASender: TObject;
  ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse;
  AException: Exception);
begin
  AResponse.SendFmt(
    '<html><head><title>Error</title></head><body><font color="red">%s</font></body></html>',
    [AException.Message], 'text/html; charset=utf-8', 500);
end;

procedure TFormUtama.BrookHTTPServer1Start(Sender: TObject);
begin
  UpdateControls;
end;

procedure TFormUtama.BrookHTTPServer1Stop(Sender: TObject);
begin
  UpdateControls;
end;

procedure TFormUtama.BrookURLRouter1Routes0Request(ASender: TObject;
  ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
  AResponse: TBrookHTTPResponse);
begin
   AResponse.Send(
    '<html><head><title>Home page</title></head><body>Home page</body></html>',
    'text/html; charset=utf-8', 200);
end;

procedure TFormUtama.BrookURLRouter1Routes1Request(ASender: TObject;
  ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
  AResponse: TBrookHTTPResponse);
var
  vNama, vKode: string;
  JSONData: TJSONData;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
begin
  if not IsAuthenticatedtoken(ARequest, AResponse) then Exit;

  if not ZConnectiondb.Connected then ZConnectiondb.Connect;

  // --- BAGIAN POST (TAMBAH DATA) ---
  if ARequest.Method = 'POST' then
  begin
    JSONData := nil;
    try
      vNama := ARequest.Payload.ToString;
      if vNama = '' then raise Exception.Create('Payload kosong');

      JSONData := GetJSON(vNama);
      if not Assigned(JSONData) then raise Exception.Create('Format JSON tidak valid');

      JSONObject := TJSONObject(JSONData);

      SQLQueryBarang.Close;
      SQLQueryBarang.SQL.Text := 'INSERT INTO barang (nama_barang, kategori, harga, stok, id_user_admin) ' +
                                 'VALUES (:nama, :kategori, :harga, :stok, :user)';

      SQLQueryBarang.ParamByName('nama').AsString := JSONObject.Get('nama', '');
      SQLQueryBarang.ParamByName('kategori').AsString := JSONObject.Get('kategori', 'Umum');
      SQLQueryBarang.ParamByName('harga').AsFloat := JSONObject.Get('harga', 0.0);
      SQLQueryBarang.ParamByName('stok').AsInteger := JSONObject.Get('stok', 0);
      SQLQueryBarang.ParamByName('user').AsInteger := JSONObject.Get('id_user', 1);

      // Zeos melakukan auto-commit secara default jika tidak diset manual transaction-nya
      SQLQueryBarang.ExecSQL;

      AResponse.Send('{"status": "success"}', 'application/json', 201);
    except
      on E: Exception do
        AResponse.SendFmt('{"status": "error", "message": "%s"}', [E.Message], 'application/json', 500);
    end;

    if Assigned(JSONData) then JSONData.Free;
    Exit;
  end
  // --- BAGIAN PUT (UPDATE DATA) ---
  else if ARequest.Method = 'PUT' then
  begin
    JSONData := nil;
    try
      vNama := ARequest.Payload.ToString;
      if vNama = '' then raise Exception.Create('Payload kosong');

      JSONData := GetJSON(vNama);
      if not Assigned(JSONData) then raise Exception.Create('Format JSON tidak valid');

      JSONObject := TJSONObject(JSONData);

      if JSONObject.Find('id') = nil then
        raise Exception.Create('ID barang harus disertakan untuk proses update');

      SQLQueryBarang.Close;
      SQLQueryBarang.SQL.Text := 'UPDATE barang SET nama_barang = :nama, kategori = :kategori, ' +
                                 'harga = :harga, stok = :stok WHERE id_barang = :id';

      SQLQueryBarang.ParamByName('id').AsInteger := JSONObject.Get('id', 0);
      SQLQueryBarang.ParamByName('nama').AsString := JSONObject.Get('nama', '');
      SQLQueryBarang.ParamByName('kategori').AsString := JSONObject.Get('kategori', 'Umum');
      SQLQueryBarang.ParamByName('harga').AsFloat := JSONObject.Get('harga', 0.0);
      SQLQueryBarang.ParamByName('stok').AsInteger := JSONObject.Get('stok', 0);

      SQLQueryBarang.ExecSQL;

      AResponse.Send('{"status": "success", "message": "Data berhasil diperbarui"}',
        'application/json', 200);
    except
      on E: Exception do
        AResponse.SendFmt('{"status": "error", "message": "%s"}', [E.Message], 'application/json', 500);
    end;

    if Assigned(JSONData) then JSONData.Free;
    Exit;
  end
  // --- BAGIAN DELETE (HAPUS DATA) ---
  else if ARequest.Method = 'DELETE' then
  begin
    try
      vKode := ARequest.Params.Values['id'];

      if vKode = '' then
        raise Exception.Create('ID barang harus disertakan untuk proses penghapusan (gunakan ?id=...)');

      SQLQueryBarang.Close;
      SQLQueryBarang.SQL.Text := 'DELETE FROM barang WHERE id_barang = :id';
      SQLQueryBarang.ParamByName('id').AsInteger := StrToIntDef(vKode, 0);

      SQLQueryBarang.ExecSQL;

      AResponse.Send('{"status": "success", "message": "Data dengan ID ' + vKode + ' berhasil dihapus"}',
        'application/json', 200);
    except
      on E: Exception do
        AResponse.SendFmt('{"status": "error", "message": "%s"}', [E.Message], 'application/json', 500);
    end;
    Exit;
  end
  // --- BAGIAN GET (READ DATA) ---
  else
  begin
    vNama := ARequest.Params.Values['nama'];
    vKode := ARequest.Params.Values['kode'];

    JSONArray := TJSONArray.Create;
    try
      SQLQueryBarang.Close;
      SQLQueryBarang.SQL.Clear;
      SQLQueryBarang.SQL.Add('SELECT id_barang, nama_barang, harga, stok FROM barang WHERE 1=1');

      if vKode <> '' then
      begin
        SQLQueryBarang.SQL.Add('AND id_barang = :kode');
        SQLQueryBarang.ParamByName('kode').AsString := vKode;
      end;

      if vNama <> '' then
      begin
        SQLQueryBarang.SQL.Add('AND nama_barang LIKE :nama');
        SQLQueryBarang.ParamByName('nama').AsString := '%' + vNama + '%';
      end;

      SQLQueryBarang.SQL.Add('LIMIT 100');
      SQLQueryBarang.Open;

      while not SQLQueryBarang.EOF do
      begin
        JSONObject := TJSONObject.Create;
        JSONObject.Add('id', SQLQueryBarang.FieldByName('id_barang').AsInteger);
        JSONObject.Add('nama', SQLQueryBarang.FieldByName('nama_barang').AsString);
        JSONObject.Add('harga', SQLQueryBarang.FieldByName('harga').AsFloat);
        JSONObject.Add('stok', SQLQueryBarang.FieldByName('stok').AsInteger);
        JSONArray.Add(JSONObject);
        SQLQueryBarang.Next;
      end;

      AResponse.Send(JSONArray.AsJSON, 'application/json; charset=utf-8', 200);

    finally
      SQLQueryBarang.Close;
      JSONArray.Free; // Pada versi terupdate, bebaskan array setelah dikonversi ke string JSON
    end;
  end;
end;

procedure TFormUtama.BrookURLRouter1Routes2Request(ASender: TObject;
  ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
  AResponse: TBrookHTTPResponse);
var
  JSONData: TJSONData;
  JSONObject, JSONRes: TJSONObject;
  vUser, vPass: string;
begin
  if ARequest.Method <> 'POST' then
  begin
    AResponse.Send('{"error": "Gunakan metode POST untuk login"}', 'application/json', 405);
    Exit;
  end;

  JSONData := nil;
  try
    JSONData := GetJSON(ARequest.Payload.ToString);
    if not Assigned(JSONData) then raise Exception.Create('Data login tidak valid');

    JSONObject := TJSONObject(JSONData);
    vUser := JSONObject.Get('username', '');
    vPass := JSONObject.Get('password', '');

    if (vUser = '') or (vPass = '') then
      raise Exception.Create('Username dan Password harus diisi');

    if not ZConnectiondb.Connected then ZConnectiondb.Connect;

    SQLQueryUser.Close;
    SQLQueryUser.SQL.Text := 'SELECT id_user, username, email FROM users ' +
                             'WHERE username = :user AND password = :pass LIMIT 1';
    SQLQueryUser.ParamByName('user').AsString := vUser;
    SQLQueryUser.ParamByName('pass').AsString := vPass;
    SQLQueryUser.Open;

    if not SQLQueryUser.IsEmpty then
    begin
      JSONRes := TJSONObject.Create;
      try
        JSONRes.Add('status', 'success');
        JSONRes.Add('message', 'Login Berhasil');
        JSONRes.Add('user_id', SQLQueryUser.FieldByName('id_user').AsInteger);
        JSONRes.Add('username', SQLQueryUser.FieldByName('username').AsString);

        AResponse.Send(JSONRes.AsJSON, 'application/json', 200);
      finally
        JSONRes.Free;
      end;
    end
    else
    begin
      AResponse.Send('{"status": "error", "message": "Username atau Password salah"}',
        'application/json', 401);
    end;

  except
    on E: Exception do
      AResponse.SendFmt('{"status": "error", "message": "%s"}', [E.Message], 'application/json', 500);
  end;

  if Assigned(JSONData) then JSONData.Free;
  SQLQueryUser.Close;
end;

procedure TFormUtama.BrookURLRouter1Routes2RequestMethod(ASender: TObject;
  ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
  AResponse: TBrookHTTPResponse; var AAllowed: Boolean);
begin

end;

procedure TFormUtama.BrookURLRouter1Routes3Request(ASender: TObject;
  ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
  AResponse: TBrookHTTPResponse);
var
  JSONData: TJSONData;
  JSONObject, JSONRes: TJSONObject;
  vUser, vPass, vToken: string;
  vID: Integer;
begin
  if ARequest.Method <> 'POST' then
  begin
    AResponse.Send('{"error": "Method not allowed"}', 'application/json', 405);
    Exit;
  end;

  JSONData := nil;
  try
    JSONData := GetJSON(ARequest.Payload.ToString);
    JSONObject := TJSONObject(JSONData);
    vUser := JSONObject.Get('username', '');
    vPass := JSONObject.Get('password', '');

    if not ZConnectiondb.Connected then ZConnectiondb.Connect;

    SQLQueryUser.Close;
    SQLQueryUser.SQL.Text := 'SELECT id_user FROM users WHERE username = :user AND password = :pass';
    SQLQueryUser.ParamByName('user').AsString := vUser;
    SQLQueryUser.ParamByName('pass').AsString := vPass;
    SQLQueryUser.Open;

    if not SQLQueryUser.IsEmpty then
    begin
      vID := SQLQueryUser.FieldByName('id_user').AsInteger;

      // Generate Token Otomatis
      vToken := Brook.SHA1(TGUID.NewGuid.ToString + vUser + DateTimeToStr(Now));

      // Simpan Token ke Database
      SQLQueryUser.Close;
      SQLQueryUser.SQL.Text := 'UPDATE users SET token = :token WHERE id_user = :id';
      SQLQueryUser.ParamByName('token').AsString := vToken;
      SQLQueryUser.ParamByName('id').AsInteger := vID;
      SQLQueryUser.ExecSQL;

      JSONRes := TJSONObject.Create;
      try
        JSONRes.Add('status', 'success');
        JSONRes.Add('token', vToken);
        JSONRes.Add('username', vUser);
        AResponse.Send(JSONRes.AsJSON, 'application/json', 200);
      finally
        JSONRes.Free;
      end;
    end
    else
      AResponse.Send('{"status": "error", "message": "Login gagal"}', 'application/json', 401);

  finally
    if Assigned(JSONData) then JSONData.Free;
    SQLQueryUser.Close;
  end;
end;

procedure TFormUtama.edPortChange(Sender: TObject);
begin
  UpdateControls;
end;

procedure TFormUtama.FormShow(Sender: TObject);
begin
  edPort.Text:= '8888';
end;

procedure TFormUtama.lbLinkClick(Sender: TObject);
begin
  OpenURL(lbLink.Caption);
end;

procedure TFormUtama.lbLinkMouseEnter(Sender: TObject);
begin
  lbLink.Font.Style := lbLink.Font.Style + [fsUnderline];
end;

procedure TFormUtama.lbLinkMouseLeave(Sender: TObject);
begin
  lbLink.Font.Style := lbLink.Font.Style + [fsUnderline];
end;

procedure TFormUtama.ZConnection1AfterReconnect(Sender: TObject);
begin

end;

procedure TFormUtama.UpdateControls;
begin
  if BrookHTTPServer1.Active then
    edPort.Value := BrookHTTPServer1.Port
  else
    BrookHTTPServer1.Port := edPort.Value;
  lbLink.Caption := Concat('http://localhost:', edPort.Value.ToString);
  acStart.Enabled := not BrookHTTPServer1.Active;
  acStop.Enabled := not acStart.Enabled;
  edPort.Enabled := acStart.Enabled;
  lbLink.Enabled := not acStart.Enabled;
end;

end.



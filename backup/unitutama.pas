unit unitUtama;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, Forms, Controls, Graphics, Dialogs,
  Spin, LCLIntf, StdCtrls, ActnList, BrookHTTPServer, BrookURLRouter,
  BrookHTTPResponse, BrookHTTPRequest, BrookUtility, fpjson,jsonparser;

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
    SQLite3Connection1: TSQLite3Connection;
    SQLQueryBarang: TSQLQuery;
    SQLTransactionBarang: TSQLTransaction;
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
    procedure edPortChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbLinkClick(Sender: TObject);
    procedure lbLinkMouseEnter(Sender: TObject);
    procedure lbLinkMouseLeave(Sender: TObject);
  private

  public
   procedure UpdateControls; {$IFNDEF DEBUG}inline;{$ENDIF}
  end;

var
  FormUtama: TFormUtama;

implementation

{$R *.lfm}

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
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
begin
  // Menggunakan Params untuk menangkap ?nama=... dan ?kode=...
  vNama := ARequest.Params.Values['nama'];
  vKode := ARequest.Params.Values['kode'];

  JSONArray := TJSONArray.Create;
  try
    // Pastikan database terhubung
    SQLite3Connection1.DatabaseName := 'database.db';
    SQLQueryBarang.Database := SQLite3Connection1;
    SQLQueryBarang.Transaction := SQLTransactionBarang;

    SQLQueryBarang.Close;
    SQLQueryBarang.SQL.Clear;
    SQLQueryBarang.SQL.Add('SELECT id_barang, nama_barang, harga, stok FROM barang WHERE 1=1');

    // Filter Kode
    if vKode <> '' then
    begin
      SQLQueryBarang.SQL.Add('AND id_barang = :kode');
      SQLQueryBarang.ParamByName('kode').AsString := vKode;
    end;

    // Filter Nama
    if vNama <> '' then
    begin
      SQLQueryBarang.SQL.Add('AND nama_barang LIKE :nama');
      SQLQueryBarang.ParamByName('nama').AsString := '%' + vNama + '%';
    end;

    SQLQueryBarang.SQL.Add('LIMIT 100');

    if not SQLite3Connection1.Connected then
      SQLite3Connection1.Open;

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
    // JSONArray dikelola oleh AResponse.Send
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


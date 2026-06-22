program RestApiConsole;

{$MODE DELPHI} // Samakan dengan unit handler agar kompatibel penuh

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, CustApp,
  ZConnection, BrookHTTPServer, BrookURLRouter, BrookHTTPRequest, BrookHTTPResponse,
  uhandlerapi;

type
  { TConsoleRouter }
  TConsoleRouter = class(TBrookURLRouter)
  protected
    // Mengamankan penanganan rute jika tidak ditemukan (404)
    procedure DoNotFound(ASender: TObject; const ARoute: string;
      ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse); override;
  end;

  { TConsoleServer }
  TConsoleServer = class(TBrookHTTPServer)
  private
    FRouter: TConsoleRouter;
  protected
    procedure DoRequest(ASender: TObject; ARequest: TBrookHTTPRequest;
      AResponse: TBrookHTTPResponse); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TBrookConsoleApp }
  TBrookConsoleApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

var
  gZConnectiondb: TZConnection;
  gIPTracker: TStringList;

{ TConsoleRouter }
procedure TConsoleRouter.DoNotFound(ASender: TObject; const ARoute: string;
  ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
  AResponse.Send('{"status": "error", "message": "Endpoint not found!"}', 'application/json', 404);
end;

{ TConsoleServer }
constructor TConsoleServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRouter := TConsoleRouter.Create(Self);

  // REGISTRASI OTOT: Panggil shared brain kita ke koleksi FRouter.Routes
  RegistrasiSemuaRute(FRouter.Routes, gZConnectiondb, gIPTracker);

  FRouter.Active := True;
end;

destructor TConsoleServer.Destroy;
begin
  FRouter.Free;
  inherited Destroy;
end;

procedure TConsoleServer.DoRequest(ASender: TObject; ARequest: TBrookHTTPRequest;
  AResponse: TBrookHTTPResponse);
begin
  // Meneruskan request jaringan secara aman ke engine router
  FRouter.Route(ASender, ARequest, AResponse);
end;

{ TBrookConsoleApp }
procedure TBrookConsoleApp.DoRun;
var
  vPort: Integer;
  vServer: TConsoleServer;
begin
  vPort := StrToIntDef(GetOptionValue('p', 'port'), 8888);

  Writeln('=====================================================');
  Writeln('   NFI KREATIF - BROOK REST API CONSOLE SERVER       ');
  Writeln('=====================================================');
  Writeln('Menginisialisasi sistem...');

  gIPTracker := TStringList.Create;
  gIPTracker.Sorted := False;

  gZConnectiondb := TZConnection.Create(nil);
  gZConnectiondb.Protocol := 'sqlite';
  //gZConnectiondb.Database := Concat(ExtractFilePath(ParamStr(0)), 'database.db');
  // MENGARAHKAN PATH KELUAR FOLDER CONSOLE, LALU MASUK KE FOLDER DB
  gZConnectiondb.Database := Concat(ExtractFilePath(ParamStr(0)), '..\db\dbtest.db');
  gZConnectiondb.Properties.Values['controls'] := 'true';
  gZConnectiondb.Properties.Values['pooled'] := 'true';
  gZConnectiondb.Properties.Values['maxconnections'] := '50';
  gZConnectiondb.Properties.Values['idle_timeout'] := '60';

  try
    gZConnectiondb.Connect;
    Writeln('-> [SUKSES] Zeos Database Connection Pool Aktif.');
  except
    on E: Exception do
    begin
      Writeln('-> [ERROR] Gagal inisialisasi Database Pool: ' + E.Message);
      gIPTracker.Free;
      Terminate;
      Exit;
    end;
  end;

  // Instansiasi Server berbasis Class-Wrapper yang baru
  vServer := TConsoleServer.Create(nil);
  vServer.Port := vPort;

  try
    vServer.Open;
    Writeln('-> [SUKSES] HTTP Server mendengarkan pada port: ' + IntToStr(vPort));
    Writeln('Tekan [CTRL + C] di terminal untuk menghentikan server.');
    Writeln('-----------------------------------------------------');

    while not Terminated do
    begin
      CheckSynchronize(100);
    end;

  finally
    Writeln('Membersihkan alokasi memori sistem...');
    vServer.Close;
    vServer.Free;
    gZConnectiondb.Disconnect;
    gZConnectiondb.Free;
    gIPTracker.Free;
  end;

  Terminate;
end;

var
  Application: TBrookConsoleApp;
begin
  Application := TBrookConsoleApp.Create(nil);
  Application.Run;
  Application.Free;
end.

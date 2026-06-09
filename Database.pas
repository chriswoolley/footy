unit Database;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, JclSysInfo,
  Db, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError;

type
  TdmData = class(TDataModule)
    dbDream: TOraSession;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
    FLevel : Integer;
  public
    { Public declarations }
    procedure Start;
    procedure Commit;
    procedure Rollback;
  end;

var
  dmData: TdmData;

implementation

{$R *.DFM}

procedure TdmData.DataModuleCreate(Sender: TObject);
var
  lUser,
  lServer : String;
begin
//  if ParamCount>0 then
//    lUser := ParamStr(1)
//  else
//    lUser := 'DREAM';
//  if ParamCount>1 then
//    lServer := ParamStr(2)
//  else
//    lServer := 'SJRDB';
//    dbDream.Params.Add('USER NAME='+lUser);
//    dbDream.Params.Add('SERVER NAME='+lServer);
//{$IFDEF Paradox}
//  dbSession.AddPassword('tesco');
//  try
//    CreateDir(GetWindowsTempFolder+'\'+dbSession.SessionName);
//  except
//    ShowMessage('Failed to create temporary directory:'+GetWindowsTempFolder+'\'+dbSession.SessionName);
//  end;
//  dbSession.PrivateDir := GetWindowsTempFolder+'\'+dbSession.SessionName;
//{$IFDEF Standalone}
//  dbSession.NetFileDir := '.\';
//  dbDream.Params.Add('.\');
//{$ELSE}
//  dbSession.NetFileDir := '\\jrbxp\data\';
//  dbDream.Params.Add('PATH=\\jrbxp\data\');
//{$ENDIF}
//{$ENDIF}
//  FLevel := 0;
  dbDream.Open;
end;

procedure TdmData.DataModuleDestroy(Sender: TObject);
begin
  dbDream.Close;
end;

procedure TdmData.Start;
begin
  Inc(FLevel);
  if FLevel=1 then
    dbDream.StartTransaction;
end;

procedure TdmData.Commit;
begin
  Dec(FLevel);
  if FLevel=0 then
    dbDream.Commit;
end;

procedure TdmData.Rollback;
begin
  Dec(FLevel);
  if FLevel=0 then
    dbDream.Rollback;
end;

initialization

dmData := TdmData.Create(Nil);

finalization

dmData.Free;
 
end.

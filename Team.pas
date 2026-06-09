unit Team;

interface

uses
  Windows, Classes, SysUtils, Contnrs, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError, Utilities,
  Database, Constants;

type
  TTeam = class(TObject)
  private
    FTeamID : Integer;
    FName : String;

    FChanged : Boolean;
    procedure SetName(AName : String);
  protected
  public
    constructor Create; overload;
    constructor Create(ATeamID : Integer; AName : String); overload;
    destructor  Destroy; override;

    procedure Save;
    procedure Load(AFrom : TOraQuery); overload;

    property TeamID : Integer read FTeamID;
    property Name : String read FName write SetName;
  published
  end;

  TTeams = class(TObject)
  private
    FItems : TObjectList;
    function GetTeam(AIndex : Integer) : TTeam;
  protected
  public
    constructor Create(AOwns : Boolean = False);
    destructor  Destroy; override;

    procedure Add(ATeam : TTeam); overload;
    procedure Add(AName : String); overload;
    procedure Clear;

    function  Find(ATeamID : Integer) : TTeam; overload;
    function  Find(AName : String) : TTeam; overload;
    function  IndexOf(ATeamID : Integer) : Integer;
    procedure Sort;

    procedure Save;
    procedure Load;

    property Team[AIndex : Integer] : TTeam read GetTeam; default;
    function Count : Integer;
  published
  end;

var
  gTeams : TTeams;

implementation

{ TTeam }

procedure TTeam.SetName(AName : String);
begin
  if FName=AName then
    exit;
  FName := AName;
  FChanged := True;
end;

constructor TTeam.Create;
begin
  inherited Create;
  FTeamID := -1;
  FName := '';
end;

constructor TTeam.Create(ATeamID : Integer; AName : String);
var
  Qry : TOraQuery;
begin
  Create;
  FTeamID := ATeamID;
  FName := AName;

  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('INSERT INTO TEAM (TEAMID,NAME) VALUES');
      Add('(:TEAMID,:NAME)');
      ParamByName('TEAMID').AsInteger := FTeamID;
      ParamByName('NAME').AsString := FName;
      ExecSQL;
    end;
    Qry.Free;
    dmData.Commit;
    FChanged := False;
  except
    dmData.Rollback;
    raise;
  end;  
end;

destructor TTeam.Destroy;
begin
  inherited;
end;

procedure TTeam.Save;
var
  Qry : TOraQuery;
begin
  if not FChanged then
    exit;
  dmData.Start;
  try  
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('UPDATE TEAM SET NAME=:NAME, WHERE TEAMID=:TEAMID');
      ParamByName('NAME').AsString := FName;
      ParamByName('TEAMID').AsInteger := FTeamID;
      ExecSQL;
      FChanged := False;
    end;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;  
end;

procedure TTeam.Load(AFrom : TOraQuery);
begin
  FTeamID := AFrom.FieldByName('TEAMID').AsInteger;
  FName := AFrom.FieldByName('NAME').AsString;
end;

{ TTeams }

function TTeams.GetTeam(AIndex: Integer): TTeam;
begin
  result := FItems[AIndex] as TTeam;
end;

constructor TTeams.Create(AOwns : Boolean = False);
begin
  inherited Create;
  FItems := TObjectList.Create(AOwns);
end;

destructor TTeams.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TTeams.Add(ATeam: TTeam);
begin
  FItems.Add(ATeam);
end;

procedure TTeams.Add(AName : String);
var
  lTeam : TTeam;
begin
  lTeam := TTeam.Create(gTeams.Count+1,AName);
  Add(lTeam);
  Save;
end;

procedure TTeams.Clear;
begin
  FItems.Clear;
end;

function Compare(Item1, Item2: Pointer): Integer;
var
  P1,P2 : TTeam;
begin
  P1 := Item1;
  P2 := Item2;
  result := P1.TeamID-P2.TeamID;
end;

function  TTeams.IndexOf(ATeamID : Integer) : Integer;
var
  C : Integer;
begin
  result := -1;
  for C := 0 to FItems.Count-1 do { Iterate } begin
    if Team[C].TeamID=ATeamID then begin
      result := C;
      break;
    end;
  end;    { for }
end;

function TTeams.Find(ATeamID : Integer) : TTeam;
var
  Idx : Integer;
begin
  result := Nil;
  Idx := IndexOf(ATeamID);
  if Idx>=0 then
    result := FItems[Idx] as TTeam;
end;

function TTeams.Find(AName : String) : TTeam;
var
  C : Integer;
begin
  result := Nil;
  for C := 0 to FItems.Count-1 do { Iterate } begin
    if Team[C].Name=AName then begin
      result := Team[C];
      break;
    end;
  end;    { for }
end;

procedure TTeams.Sort;
begin
  FItems.Sort(Compare);
end;

procedure TTeams.Save;
begin
end;

procedure TTeams.Load;
var
  Play : TTeam;
  Qry : TOraQuery;
begin
  Clear;
  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry do begin
    SQL.Add('SELECT * FROM Team ORDER BY TeamID');
    Open;
    while not Eof do begin
      Play := TTeam.Create;
      Play.Load(Qry);
      Add(Play);
      SetToNil(Play);
      Next;
    end;    { while }
    Close;
  end;    { with }
  Qry.Free;
end;

function TTeams.Count: Integer;
begin
  result := FItems.Count;
end;

end.

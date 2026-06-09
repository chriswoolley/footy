unit Person;

interface

uses
  Windows, Classes, SysUtils, Contnrs, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError, Utilities, Constants, Database, Squad;

type
  TPerson = class(TObject)
  private
    FChanged : Boolean;
    FID : Integer;
    FUserName : String;
    FPassword : String;
    FTeam     : String;
    FEMail : String;
    FSquads : TSquads;
  protected
    procedure SetEMail(AEMail : String);
    procedure SetTeam(ATeam : String);
    procedure SetUsername(AUsername : String);
    procedure SetPassword(APassword : String);
    function GetPrice : Extended;
  public
    constructor Create;
    destructor  Destroy; override;

    procedure Load(AFrom : TOraQuery);
    procedure Save;
    procedure Add;

    property Changed : Boolean read FChanged write FChanged;
    property ID : Integer read FID;
    property UserName : String read FUserName write SetUsername;
    property Password : String read FPassword write SetPassword;
    property Team     : String read FTeam write SetTeam;
    property EMail    : String read FEMail write SetEMail;
    property Price    : Extended read GetPrice;
    property Squads   : TSquads read FSquads;
  published
  end;

  TPersons = class(TObject)
  private
    FItems : TObjectList;
    function GetPerson(AIndex : Integer) : TPerson;
  protected
  public
    constructor Create(AOwns : Boolean = True);
    destructor  Destroy; override;

    procedure Add(APerson : TPerson);
    procedure Clear;

    function  Find(APersonID : Integer): TPerson;
    function  IndexOf(AID : Integer) : Integer;
    procedure Sort;

    procedure Save;
    procedure Load;

    property Person[AIndex : Integer] : TPerson read GetPerson; default;
    function Count : Integer;
  published
  end;

var
  gPersons : TPersons;
  
implementation

{ TPerson }

procedure TPerson.SetEMail(AEMail : String);
begin
  FEMail := AEMail;
  FChanged := True;
end;

procedure TPerson.SetTeam(ATeam : String);
begin
  FTeam := ATeam;
  FChanged := True;
end;

procedure TPerson.SetUsername(AUsername : String);
begin
  FUsername := AUserName;
  FChanged := True;
end;

procedure TPerson.SetPassword(APassword : String);
begin
  FPassword := APassword;
  FChanged := True;
end;

function TPerson.GetPrice : Extended;
var
  lPrice : Extended;
  C : Integer;
begin
  lPrice := 0;
  for C := 0 to FSquads.Count-1 do begin
    lPrice := lPrice + FSquads[C].Bid;
  end;
  result := lPrice;
end;

constructor TPerson.Create;
begin
  inherited Create;
  FSquads := TSquads.Create;
end;

destructor TPerson.Destroy;
begin
  inherited;
end;

procedure TPerson.Load(AFrom : TOraQuery);
var
  lSquad : TSquad;
  Qry : TOraQuery;
begin
  FID := AFrom.FieldByName('PERSONID').AsInteger;
  FUserName := AFrom.FieldByName('NAME').AsString;
  FPassword := AFrom.FieldByName('PASSWORD').AsString;
  FEMail := AFrom.FieldByName('EMAIL').AsString;
  FTeam := AFrom.FieldByName('TEAM').AsString;
  FSquads.Clear;
  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    Add('SELECT * FROM SQUAD WHERE PERSONID=:PERSONID');
    ParamByName('PERSONID').AsInteger := FID;
    Open;
    while not Eof do begin
      lSquad := TSquad.Create;
      lSquad.Load(Qry);
      FSquads.Add(lSquad);
      lSquad := Nil;
      Next;
    end;    { while }
    Close;
  end;
  Qry.Free;
end;

procedure TPerson.Save;
var
  Qry : TOraQuery;
begin
  dmData.Start;
  if FChanged then begin
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('UPDATE PERSON SET NAME=:NAME, EMAIL=:EMAIL, TEAM=:TEAM, PASSWORD=:PASSWORD WHERE PERSONID=:PERSONID');
      ParamByName('PERSONID').AsInteger := FID;
      ParamByName('NAME').AsString := FUsername;
      ParamByName('EMAIL').AsString := FEMail;
      ParamByName('TEAM').AsString := FTeam;
      ParamByName('PASSWORD').AsString := FPassword;
      ExecSQL;
    end;
    Qry.Free;
  end;
  dmData.Commit;
end;

procedure TPerson.Add;
var
  Qry : TOraQuery;
  lOK : Boolean;
begin
  dmData.Start;
  if FChanged then begin
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('SELECT COUNT(*) FROM PERSON WHERE NAME=:NAME');
      ParamByName('NAME').AsString := FUsername;
      Open;
      lOK := Fields[0].AsInteger=0;
      Close;
      Clear;
      if lOK then begin
        Add('SELECT MAX(PERSONID)+1 FROM PERSON');
        Open;
        FID := Fields[0].AsInteger;
        Close;
        Clear;
        Add('INSERT INTO PERSON (PERSONID,NAME,PASSWORD,EMAIL,TEAM)');
        Add('VALUES (:PERSONID,:NAME,:PASSWORD,:EMAIL,:TEAM)');
        ParamByName('PERSONID').AsInteger := FID;
        ParamByName('NAME').AsString := FUsername;
        ParamByName('EMAIL').AsString := FEMail;
        ParamByName('TEAM').AsString := FTeam;
        ParamByName('PASSWORD').AsString := FPassword;
        ExecSQL;
      end;  
    end;
    Qry.Free;
  end;
  dmData.Commit;
end;

{ TPersons }

function TPersons.GetPerson(AIndex: Integer): TPerson;
begin
  result := FItems[AIndex] as TPerson;
end;

constructor TPersons.Create(AOwns : Boolean = True);
begin
  inherited Create;
  FItems := TObjectList.Create(AOwns);
end;

destructor TPersons.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TPersons.Add(APerson: TPerson);
begin
  FItems.Add(APerson);
end;

procedure TPersons.Clear;
begin
  FItems.Clear;
end;

function Compare(Item1, Item2: Pointer): Integer;
var
  P1,P2 : TPerson;
begin
  P1 := Item1;
  P2 := Item2;
  result := P1.ID-P2.ID;
end;

function  TPersons.Find(APersonID : Integer): TPerson;
begin
  result := FItems[IndexOf(APersonID)] as TPerson;
end;

function  TPersons.IndexOf(AID : Integer) : Integer;
var
  C : Integer;
begin
  result := -1;
  for C := 0 to FItems.Count-1 do { Iterate } begin
    if Person[C].ID=AID then begin
      result := C;
      break;
    end;
  end;    { for }
end;

procedure TPersons.Sort;
begin
  FItems.Sort(Compare);
end;

procedure TPersons.Save;
var
  Per : TPerson;
  Qry : TOraQuery;
  C : Integer;
begin
  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('UPDATE PERSON SET ');
      Add('EMAIL=:EMAIL, PASSWORD=:PASSWORD, TEAM=:TEAM');
      Add('WHERE PERSONID=:PERSONID');
      for C := 0 to FItems.Count-1 do begin
        Per := FItems[C] as TPerson;
        if Per.Changed then begin
          ParamByName('PERSONID').AsInteger := Per.ID;
          ParamByName('EMAIL').AsString := Per.EMail;
          ParamByName('PASSWORD').AsString := Per.Password;
          ParamByName('TEAM').AsString := Per.Team;
          ExecSQL;
          Per.Changed := False;
        end;
      end;    { for }
    end;    { with }
    Qry.Free;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;  
end;

procedure TPersons.Load;
var
  Play : TPerson;
  Qry : TOraQuery;
begin
  Clear;
  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry do begin
    SQL.Add('SELECT * FROM PERSON ORDER BY PERSONID');
    Open;
    while not Eof do begin
      Play := TPerson.Create;
      Play.Load(Qry);
      Add(Play);
      SetToNil(Play);
      Next;
    end;    { while }
    Close;
  end;    { with }
  Qry.Free;
end;

function TPersons.Count: Integer;
begin
  result := FItems.Count;
end;

end.

unit Point;

interface

uses
  Windows, Classes, Contnrs, SysUtils, DBTables, DBAccess, Ora, OraSmart, MemDS, OraError, Utilities, Constants, Database, Math;

type
  TPoint = class(TObject)
  private
    FPointsID : Integer;
    FPlayerID : Integer;
    FPoints   : Integer;
    FDelta    : Integer;
    FFromAt   : TDateTime;
    FUntilAt  : TDateTime;
    FFlag     : Boolean;

    FChanged : Boolean;
    FDelete : Boolean;
    procedure SetUntilAt(AUntilAt : TDateTime);
    procedure SetFromAt(AFromAt : TDateTime);
    procedure SetDelta(ADelta : Integer);
    procedure SetPoints(APoints : Integer);
    procedure SetFlag(AFlag : Boolean);
  protected
  public
    constructor Create; overload;
    constructor Create(APointsID,APlayerID,APoints,ADelta : Integer; AFromAt,AUntilAt : TDateTime); overload;
    destructor  Destroy; override;

    property PointsID : Integer read FPointsID;
    property PlayerID : Integer read FPlayerID;
    property Points   : Integer read FPoints write SetPoints;
    property Delta    : Integer read FDelta write SetDelta;
    property FromAt   : TDateTime read FFromAt write SetFromAt;
    property UntilAt  : TDateTime read FUntilAt write SetUntilAt;
    property Flag     : Boolean read FFlag write SetFlag;

    property Changed : Boolean read FChanged write FChanged;
    property Delete : Boolean read FDelete write FDelete;
  published
  end;

  TPoints = class(TObject)
  private
    FItems : TObjectList;
    function GetPoint(AIndex: Integer): TPoint;
  protected
  public
    constructor Create;
    destructor  Destroy; override;

    function Find(APlayerID : Integer) : TPoint;
    procedure Add(APoint : TPoint);

    procedure Fill(APlayerID : Integer; AInto : TObjectList);
    procedure Load(AAll : Boolean);
    procedure Save;
    function Last : TDateTime;

    property Point[AIndex : Integer] : TPoint read GetPoint; default; 
    function Count : Integer;
  end;

implementation

{ TPoint }

procedure TPoint.SetDelta(ADelta : Integer);
begin
  if FDelta=ADelta then
    exit;
  FDelta := ADelta;
  FChanged := True;
end;

procedure TPoint.SetPoints(APoints : Integer);
begin
  if FPoints=APoints then
    exit;
  FPoints := APoints;
  FChanged := True;
end;

procedure TPoint.SetFlag(AFlag : Boolean);
begin
  if FFlag=AFlag then
    exit;
  FFlag := AFlag;
  FChanged := True;
end;

procedure TPoint.SetUntilAt(AUntilAt : TDateTime);
begin
  if FUntilAt=AUntilAt then
    exit;
  FUntilAt := AUntilAt;
  FChanged := True;
end;

procedure TPoint.SetFromAt(AFromAt : TDateTime);
begin
  if FFromAt=AFromAt then
    exit;
  FFromAt := AFromAt;
  FChanged := True;
end;

constructor TPoint.Create;
begin
  inherited Create;
  FPointsID := -1;
  FChanged := False;
  FDelete := False;
  FFlag   := False;
end;

constructor TPoint.Create(APointsID, APlayerID, APoints, ADelta: Integer; AFromAt, AUntilAt: TDateTime);
var
  Qry : TOraQuery;
begin
  Create;
  FPointsID := APointsID;
  FPlayerID := APlayerID;
  FPoints   := APoints;
  FDelta    := ADelta;
  FFromAt   := AFromAt;
  FUntilAt  := AUntilAt;

  if FPointsID<>-1 then
    exit;

  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('SELECT NVL(MAX(POINTSID)+1,1) AS ID FROM POINTS');
      Open;
      FPointsID := Fields[0].AsInteger;
      Close;
      Clear;
    end;    { with }

    with Qry,SQL do begin
      Add('INSERT INTO POINTS (POINTSID,PLAYERID,POINTS,DELTA,FROMAT,UNTILAT) VALUES');
      Add('(:POINTSID,:PLAYERID,:POINTS,:DELTA,:FROMAT,:UNTILAT)');
      ParamByName('POINTSID').AsInteger := FPointsID;
      ParamByName('PLAYERID').AsInteger := FPlayerID;
      ParamByName('POINTS').AsInteger := FPoints;
      ParamByName('DELTA').AsInteger := FDelta;             
      ParamByName('FROMAT').AsDateTime := FFromAt;
      ParamByName('UNTILAT').AsDateTime := FUntilAt;
      ExecSQL;
    end;    { with }
    Qry.Free;
    dmData.Commit;
  except
    dmData.Rollback;
    raise;
  end;
end;

destructor TPoint.Destroy;
begin
  inherited;
end;

{ TPoints }

function TPoints.GetPoint(AIndex: Integer): TPoint;
begin
  result := FItems[AIndex] as TPoint;
end;

constructor TPoints.Create;
begin
  inherited Create;
  FItems := TObjectList.Create;
end;

destructor TPoints.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TPoints.Find(APlayerID : Integer) : TPoint;
var
  C : Integer;
  Poi : TPoint;
begin
  result := Nil;
  for C := 0 to FItems.Count-1 do { Iterate } begin
    Poi := FItems[C] as TPoint;
    if Poi.PlayerID=APlayerID then begin
      result := Poi;
      break;
    end;
  end;    { for }
end;

procedure TPoints.Fill(APlayerID : Integer; AInto : TObjectList);
var
  C : Integer;
  Poi : TPoint;
begin
  for C := 0 to FItems.Count-1 do { Iterate } begin
    Poi := FItems[C] as TPoint;
    if Poi.PlayerID=APlayerID then begin
      AInto.Add(Poi);
    end;
  end;    { for }
end;

procedure TPoints.Add(APoint : TPoint);
begin
  FItems.Add(APoint);
end;

procedure TPoints.Load(AAll : Boolean);
var
  Qry : TOraQuery;
  Poi : TPoint;
begin
  {Load just the current set of points}
  FItems.Clear;

  Qry := TOraQuery.Create(Nil);
  Qry.Session := dmData.dbDream;
  with Qry,SQL do begin
    if AAll then
      Add('SELECT * FROM POINTS ORDER BY POINTSID')
    else begin
      Add('SELECT * FROM POINTS WHERE UNTILAT>:UNTILAT ORDER BY POINTSID');
      ParamByName('UNTILAT').AsDateTime := Now;
    end;
    Open;
    while not Eof do begin
      Poi := TPoint.Create(FieldByName('POINTSID').AsInteger,FieldByName('PLAYERID').AsInteger,
                           FieldByName('POINTS').AsInteger,FieldByName('DELTA').AsInteger,
                           FieldByName('FROMAT').AsDateTime,FieldByName('UNTILAT').AsDateTime);
      FItems.Add(Poi);
      SetToNil(Poi);
      Next;
    end;    { while }
    Close;
  end;
  Qry.Free;
end;

procedure TPoints.Save;
var
  C : Integer;
  Qry : TOraQuery;
  Poi : TPoint;
begin
  dmData.Start;
  try
    Qry := TOraQuery.Create(Nil);
    Qry.Session := dmData.dbDream;
    with Qry,SQL do begin
      Add('UPDATE POINTS SET POINTS=:POINTS,FROMAT=:FROMAT,UNTILAT=:UNTILAT,DELTA=:DELTA,FLAG=:FLAG WHERE POINTSID=:POINTSID');
    end;

    for C := 0 to FItems.Count-1 do { Iterate } begin
      Poi := FItems[C] as TPoint;
      if Poi.Changed and (not Poi.Delete) then begin
        Qry.ParamByName('POINTSID').AsInteger := Poi.PointsID;
        Qry.ParamByName('POINTS').AsInteger := Poi.Points;
        Qry.ParamByName('DELTA').AsInteger := Poi.Delta;
        Qry.ParamByName('FROMAT').AsDateTime := Poi.FromAt;
        Qry.ParamByName('UNTILAT').AsDateTime := Poi.UntilAt;
{$IFDEF Paradox}        
        Qry.ParamByName('FLAG').AsBoolean := Poi.Flag;
{$ELSE}        
        Qry.ParamByName('FLAG').AsString := gcTorF[Poi.Flag];
{$ENDIF}        
        Qry.ExecSQL;
        Poi.Changed := False;
      end;
    end;    { for }

    with Qry,SQL do begin
      Clear;
      Add('DELETE FROM POINTS WHERE POINTSID=:POINTSID');
    end;    { with }
    
    for C := FItems.Count-1 downto 0 do { Iterate } begin
      Poi := FItems[C] as TPoint;
      if Poi.Delete then begin
        Qry.ParamByName('POINTSID').AsInteger := Poi.PointsID;
        Qry.ExecSQL;
        FItems.Delete(C);
      end;
    end;    { for }

    Qry.Free;
    dmData.Commit;
  except  
    dmData.Rollback;
    raise;
  end;
end;

function TPoints.Last : TDateTime;
var
  C : Integer;
  L : TDateTime;
begin
  L := 0;
  for C := 0 to FItems.Count-1 do { Iterate } begin
    L := Max(L,(FItems[C] as TPoint).FromAt);
  end;    { for }
  result := L;
end;

function TPoints.Count : Integer;
begin
  result := FItems.Count;
end;

end.

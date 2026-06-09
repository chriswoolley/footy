unit TestChart;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, TeeProcs, TeEngine, Chart, Series;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Panel1: TPanel;
    chtTeam: TChart;
    Series1: TLineSeries;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.Button1Click(Sender: TObject);
const
  X2 : Array[0..10] of Integer = (0,1,2,3,4,5,4,3,2,1,0);
  Y2 : Array[0..10] of Integer = (0,2,4,6,8,10,12,14,16,18,20);
var
  X,
  Y,
  D,
  C : Integer;
  Series : TChartSeries;
  procedure NewSeries;
  const
    Style : TSeriesPointerStyle = psRectangle;
  begin
    Series := TFastLineSeries.Create(chtTeam);
    Series.Title := 'Test';
    Series.ParentChart := chtTeam;
    Series.Tag := 1;
    Series.Marks.Style := smsValue;
//    (Series as TFastLineSeries).Pointer.Visible := True;
    (Series as TFastLineSeries).LinePen.Width := 2;
//    (Series as TFastLineSeries).Pointer.Style := Style;
    Style := Succ(Style);
    if Style=psSmalLDot then
      Style := psRectangle;
//    if chkFrom.Checked then
//      Series.AddXY(dtmFrom.Date,0,DateToStr(dtmFrom.Date))
//    else
//      Series.AddXY(Min,0,DateToStr(Min));
  end;
begin
  Series := Nil;
  Y := 0;
  chtTeam.RemoveAllSeries;
  for C := 0 to 10 do begin
    X := C;
    Y := Y + Random(5);
    if (Series=Nil) then
      NewSeries;
    Series.AddXY(X,Y,IntToStr(Y));
  end;    { while }
  Series := Nil;
  for C := 0 to 10 do begin
    X := X2[C];
    Y := Y2[C];
    if (Series=Nil) then
      NewSeries;
    Series.AddXY(X,Y,IntToStr(Y));
  end;    { while }
end;

end.

object FrmGraph: TFrmGraph
  Left = 716
  Top = 362
  Width = 530
  Height = 417
  Caption = 'Graph'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pagPages: TPageControl
    Left = 0
    Top = 0
    Width = 522
    Height = 383
    ActivePage = tabSelection
    Align = alClient
    TabIndex = 0
    TabOrder = 0
    OnChange = pagPagesChange
    object tabSelection: TTabSheet
      Caption = 'Selection'
      DesignSize = (
        514
        355)
      object lblFrom: TLabel
        Left = 24
        Top = 12
        Width = 23
        Height = 13
        Caption = 'From'
      end
      object lblTo: TLabel
        Left = 24
        Top = 36
        Width = 13
        Height = 13
        Caption = 'To'
      end
      object lblTeams: TLabel
        Left = 24
        Top = 80
        Width = 32
        Height = 13
        Caption = 'Teams'
      end
      object lblPlayers: TLabel
        Left = 280
        Top = 78
        Width = 34
        Height = 13
        Caption = 'Players'
      end
      object dtmFrom: TDateTimePicker
        Left = 64
        Top = 8
        Width = 186
        Height = 21
        CalAlignment = dtaLeft
        Date = 37488.5346740625
        Time = 37488.5346740625
        DateFormat = dfShort
        DateMode = dmComboBox
        Kind = dtkDate
        ParseInput = False
        TabOrder = 0
        OnChange = dtmFromChange
      end
      object dtmTo: TDateTimePicker
        Left = 64
        Top = 32
        Width = 186
        Height = 21
        CalAlignment = dtaLeft
        Date = 37853.5347013657
        Time = 37853.5347013657
        DateFormat = dfShort
        DateMode = dmComboBox
        Kind = dtkDate
        ParseInput = False
        TabOrder = 1
        OnChange = dtmToChange
      end
      object cklTeam: TCheckListBox
        Left = 64
        Top = 80
        Width = 185
        Height = 273
        OnClickCheck = cklTeamClickCheck
        Anchors = [akLeft, akTop, akBottom]
        ItemHeight = 13
        TabOrder = 2
        OnClick = cklTeamClick
        OnDblClick = cklTeamDblClick
        OnMouseDown = cklTeamMouseDown
      end
      object chkChange: TCheckBox
        Left = 65
        Top = 57
        Width = 97
        Height = 17
        Caption = 'Changes'
        TabOrder = 3
        OnClick = chkChangeClick
      end
      object chkFrom: TCheckBox
        Left = 256
        Top = 10
        Width = 97
        Height = 17
        Caption = 'From'
        TabOrder = 4
        OnClick = chkFromClick
      end
      object chkTo: TCheckBox
        Left = 256
        Top = 34
        Width = 97
        Height = 17
        Caption = 'To'
        TabOrder = 5
        OnClick = chkToClick
      end
      object cklPlayer: TCheckListBox
        Left = 320
        Top = 80
        Width = 185
        Height = 273
        Anchors = [akLeft, akTop, akBottom]
        ItemHeight = 13
        TabOrder = 6
        OnClick = cklTeamClick
        OnDblClick = cklTeamDblClick
      end
      object edtCSV: TEdit
        Left = 320
        Top = 8
        Width = 185
        Height = 21
        TabOrder = 7
      end
    end
    object tabTeam: TTabSheet
      Caption = 'Team'
      ImageIndex = 1
      object chtTeam: TChart
        Left = 0
        Top = 0
        Width = 514
        Height = 355
        BackWall.Brush.Color = clWhite
        BackWall.Brush.Style = bsClear
        Title.Text.Strings = (
          'Dream Team Scores')
        View3D = False
        Align = alClient
        TabOrder = 0
      end
    end
    object tabPlayer: TTabSheet
      Caption = 'Player'
      ImageIndex = 3
      object chtPlayer: TChart
        Left = 0
        Top = 0
        Width = 514
        Height = 355
        BackWall.Brush.Color = clWhite
        BackWall.Brush.Style = bsClear
        Title.Text.Strings = (
          'Dream Team Scores')
        View3D = False
        Align = alClient
        TabOrder = 0
      end
    end
  end
end

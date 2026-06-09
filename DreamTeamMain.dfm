object FrmDreamTeamScore: TFrmDreamTeamScore
  Left = 246
  Top = 402
  Width = 894
  Height = 397
  Caption = 'FrmDreamTeamScore'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object mmoHTML: TMemo
    Left = 0
    Top = 73
    Width = 4096
    Height = 189
    TabOrder = 1
  end
  object webBrowse: TWebBrowser
    Left = 0
    Top = 73
    Width = 4096
    Height = 273
    Align = alClient
    TabOrder = 0
    OnNavigateComplete2 = webBrowseNavigateComplete2
    OnDocumentComplete = webBrowseDocumentComplete
    ControlData = {
      4C00000055A70100371C00000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126202000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 4096
    Height = 73
    Align = alTop
    TabOrder = 2
    object Label1: TLabel
      Left = 8
      Top = 48
      Width = 3
      Height = 13
    end
    object btnUpdate: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Update'
      TabOrder = 0
      OnClick = btnUpdateClick
    end
    object btnWeb: TButton
      Left = 88
      Top = 8
      Width = 19
      Height = 25
      TabOrder = 1
      OnClick = btnWebClick
    end
    object btnDetails: TButton
      Left = 192
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Details'
      TabOrder = 2
      OnClick = btnDetailsClick
    end
    object btnRetry: TButton
      Left = 272
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Retry'
      TabOrder = 3
      OnClick = btnRetryClick
    end
    object btnReParse: TButton
      Left = 352
      Top = 8
      Width = 75
      Height = 25
      Caption = 'btnReParse'
      TabOrder = 4
      OnClick = btnReParseClick
    end
    object btnPack: TButton
      Left = 432
      Top = 8
      Width = 75
      Height = 25
      Caption = 'btnPack'
      TabOrder = 5
      OnClick = btnPackClick
    end
    object btnEMail: TButton
      Left = 512
      Top = 8
      Width = 75
      Height = 25
      Caption = 'btnEMail'
      TabOrder = 6
      OnClick = btnEMailClick
    end
    object btnCheck: TButton
      Left = 752
      Top = 8
      Width = 75
      Height = 25
      Caption = 'btnCheck'
      TabOrder = 7
      OnClick = btnCheckClick
    end
    object btnAuction: TButton
      Left = 112
      Top = 40
      Width = 75
      Height = 33
      Caption = 'btnAuction'
      TabOrder = 8
      OnClick = btnAuctionClick
    end
    object btnRumor: TButton
      Left = 432
      Top = 40
      Width = 75
      Height = 25
      Caption = 'btnRumor'
      TabOrder = 9
      OnClick = btnRumorClick
    end
    object btnPlayers: TButton
      Left = 112
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Players'
      TabOrder = 10
      OnClick = btnPlayersClick
    end
    object btnStop: TButton
      Left = 592
      Top = 8
      Width = 75
      Height = 25
      Caption = 'btnStop'
      TabOrder = 11
      OnClick = btnStopClick
    end
    object btnServe: TButton
      Left = 592
      Top = 40
      Width = 75
      Height = 25
      Caption = 'btnServe'
      TabOrder = 12
      OnClick = btnServeClick
    end
  end
  object mmoStages: TMemo
    Left = 8
    Top = 88
    Width = 865
    Height = 241
    Lines.Strings = (
      
        'http://www.dreamteamfc.com/fantasyfootball/1011/?CMP=KNGvccp1-dr' +
        'eam%20team'
      
        'http://www.dreamteamfc.com/fantasyfootball/1011/ViewPlayerList.a' +
        'spx?pp=1'
      
        'http://www.dreamteamfc.com/fantasyfootball/1011/ViewPlayerList.a' +
        'spx?pp=2'
      
        'http://www.dreamteamfc.com/fantasyfootball/1011/ViewPlayerList.a' +
        'spx?pp=4'
      
        'http://www.dreamteamfc.com/fantasyfootball/1011/ViewPlayerList.a' +
        'spx?pp=6'
      
        'http://www.dreamteamfc.com/fantasyfootball/1011/ViewPlayerProfil' +
        'e.aspx?pid=XXX')
    TabOrder = 3
    Visible = False
  end
  object dlgOpen: TOpenDialog
    Options = [ofEnableSizing]
    Left = 104
    Top = 216
  end
end

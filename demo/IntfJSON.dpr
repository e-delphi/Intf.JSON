program IntfJSON;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.JSON,
  System.Variants,
  System.DateUtils,
  Winapi.Windows,
  Intf.JSON in '..\src\Intf.JSON.pas';

function ISO2Format(sISO: String): String;
begin
  Result := FormatDateTime('dd/mm/yyyy hh:nn:ss.zzz', ISO8601ToDate(sISO));
end;

procedure MaisAntigo;
var
  oJSON: TJSONObject;
  oItem: TJSONObject;
  aJSON: TJSONArray;
begin
  oJSON := TJSONObject.Create;
  try
    oJSON.AddPair('fruta',      'Abacate');
    oJSON.AddPair('estado',     'Verde');
    oJSON.AddPair('colhida',    DateToISO8601(Now));
    oJSON.AddPair('semente',    TJSONBool.Create(True));
    oJSON.AddPair('quantidade', TJSONNumber.Create(1));
    oJSON.AddPair('peso',       TJSONNumber.Create(0.3));
    oJSON.AddPair('dono',       TJSONNull.Create);

    oItem := TJSONObject.Create;
    oJSON.AddPair('objeto', oItem);

    oItem.AddPair('a', 'b');

    aJSON := TJSONArray.Create;
    oJSON.AddPair('lista', aJSON);

    aJSON.AddElement(TJSONNumber.Create(0));
    aJSON.Add('lista');

    Writeln(oJSON.ToJSON);
    Writeln(
      oJSON.GetValue('fruta').Value, ' - ',
      oJSON.GetValue('estado').Value, ' - ',
      ISO2Format(oJSON.GetValue('colhida').Value), ' - ',
      TJSONBool(oJSON.GetValue('semente')).AsBoolean, ' - ',
      TJSONNumber(oJSON.GetValue('quantidade')).AsInt, ' - ',
      TJSONNumber(oJSON.GetValue('peso')).AsDouble
    );
  finally
    FreeAndNil(oJSON);
  end;
end;

procedure Antigo;
var
  oJSON: TJSONObject;
begin
  oJSON := TJSONObject.Create;
  try
    oJSON.AddPair('fruta',      'Abacate');
    oJSON.AddPair('estado',     'Verde');
    oJSON.AddPair('colhida',    DateToISO8601(Now));
    oJSON.AddPair('semente',    TJSONBool.Create(True));
    oJSON.AddPair('quantidade', TJSONNumber.Create(1));
    oJSON.AddPair('peso',       TJSONNumber.Create(0.3));
    oJSON.AddPair('dono',       TJSONNull.Create);
    oJSON.AddPair('objeto',     TJSONObject.Create.AddPair('a', 'b'));
    oJSON.AddPair('lista',      TJSONArray.Create.Add(0).Add('lista'));

    Writeln(oJSON.ToJSON);
    Writeln(
      oJSON.GetValue('fruta').Value, ' - ', 
      oJSON.GetValue('estado').Value, ' - ',
      ISO2Format(oJSON.GetValue('colhida').Value), ' - ',
      TJSONBool(oJSON.GetValue('semente')).AsBoolean, ' - ',
      TJSONNumber(oJSON.GetValue('quantidade')).AsInt, ' - ',
      TJSONNumber(oJSON.GetValue('peso')).AsDouble
    );
  finally
    FreeAndNil(oJSON);
  end;
end;

procedure Novo;
var
  Intf: IJSONObject;
begin
  Intf                 := TIJSONObject.New;
  Intf.JSON.fruta      := 'Abacate';
  Intf.JSON.estado     := 'Verde';
  Intf.JSON.colhida    := Now;
  Intf.JSON.semente    := True;
  Intf.JSON.quantidade := 1;
  Intf.JSON.peso       := 0.3;
  Intf.JSON.dono       := Null;
  Intf.JSON.objeto     := TIJSONObject.Init;
  Intf.JSON.objeto.a   := 'b';
  Intf.JSON.lista      := TIJSONArray.Init;
  Intf.JSON.lista.add  := 0;
  Intf.JSON.lista.add  := 'lista';

  Writeln(Intf.AsJSON.ToJSON);
  Writeln(
    Intf.JSON.fruta, ' - ',
    Intf.JSON.estado, ' - ',
    Intf.JSON.colhida, ' - ',
    Boolean(Intf.JSON.semente), ' - ',
    Intf.JSON.quantidade, ' - ',
    Double(Intf.JSON.peso)
  );
end;

procedure MaisNovo;
var
  Intf: IJSONObject;
begin
  TIJSONObject.New(Intf)
    .fruta('Abacate')
    .estado('Verde')
    .colhida(Now)
    .semente(True)
    .quantidade(1)
    .peso(0.3)
    .dono(Null)
    .objeto(TIJSONObject.Init.a('b'))
    .lista(0, 'lista');

  Writeln(Intf.AsJSON.ToJSON);
  Writeln(
    Intf.JSON.fruta, ' - ',
    Intf.JSON.estado, ' - ',
    Intf.JSON.colhida, ' - ',
    Boolean(Intf.JSON.semente), ' - ',
    Intf.JSON.quantidade, ' - ',
    Double(Intf.JSON.peso)
  );
end;

procedure OnReportMemoryLeaks;
var
  InputRec: TInputRecord;
  NumRead: Cardinal;
  OldKeyMode: DWORD;
  StdIn : NativeUInt;
begin
  StdIn := GetStdHandle(STD_INPUT_HANDLE);
  GetConsoleMode(StdIn, OldKeyMode);
  SetConsoleMode(StdIn, 0);
  repeat
    ReadConsoleInput(StdIn, InputRec, 1, NumRead);
  until (InputRec.EventType and KEY_EVENT <> 0) and InputRec.Event.KeyEvent.bKeyDown;
  SetConsoleMode(StdIn, OldKeyMode);
end;

begin
  ExitProcessProc := OnReportMemoryLeaks;
  ReportMemoryLeaksOnShutdown := True;

  MaisAntigo;
  Writeln;

  Antigo;
  Writeln;

  Novo;
  Writeln;

  MaisNovo;
  Writeln;
end.

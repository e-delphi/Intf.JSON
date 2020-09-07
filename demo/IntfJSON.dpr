program IntfJSON;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.JSON,
  System.Variants,
  System.DateUtils,
  Intf.JSON;

{$Region' Auxiliar '}

function ISO2Format(sISO: String): String;
begin
  Result := FormatDateTime('dd/mm/yyyy hh:nn:ss.zzz', ISO8601ToDate(sISO));
end;

{$EndRegion}

procedure Tradicional;
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
    oJSON.AddPair('lista',      TJSONArray.Create.Add(0).Add('2º item').Add('3º item'));

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

procedure InterfaceJSON;
var
  Intf: TIJSONObject;
begin
  Intf := TIJSONObject.Create;
  Intf.JSON.fruta      := 'Abacate';
  Intf.JSON.estado     := 'Verde';
  Intf.JSON.colhida    := Now;
  Intf.JSON.semente    := True;
  Intf.JSON.quantidade := 1;
  Intf.JSON.peso       := 0.3;
  Intf.JSON.dono       := Null;
  Intf.JSON.objeto     := TIJSONObject.Create.JSON;
  Intf.JSON.objeto.a   := 'b';
  Intf.JSON.lista      := TIJSONArray.Create.JSON;
  Intf.JSON.lista.add  := 0;
  Intf.JSON.lista.add  := '2º item';
  Intf.JSON.lista.add  := '3º item';

  Writeln(Intf.AsJSON.ToJSON);
  Writeln(
    Intf.JSON.fruta, ' - ',
    Intf.JSON.estado, ' - ',
    ISO2Format(Intf.JSON.colhida), ' - ',
    Boolean(Intf.JSON.semente), ' - ',
    Intf.JSON.quantidade, ' - ',
    Double(Intf.JSON.peso)
  );
end;

procedure FluenteInterfaceJSON;
var
  Intf: TIJSONObject;
begin
  Intf := TIJSONObject.Create;
  Intf.JSON
    .fruta('Abacate')
    .estado('Verde')
    .colhida(Now)
    .semente(True)
    .quantidade(1)
    .peso(0.3)
    .dono(Null)
    .objeto(TIJSONObject.New.a('b'))
    .lista(0, '2º item', '3º item');

  Writeln(Intf.AsJSON.ToJSON);
  Writeln(
    Intf.JSON.fruta, ' - ',
    Intf.JSON.estado, ' - ',
    ISO2Format(Intf.JSON.colhida), ' - ',
    Boolean(Intf.JSON.semente), ' - ',
    Intf.JSON.quantidade, ' - ',
    Double(Intf.JSON.peso)
  );
end;

begin
  Tradicional;
  Writeln;

  InterfaceJSON;
  Writeln;

  FluenteInterfaceJSON;
  Writeln;

  Readln;
end.

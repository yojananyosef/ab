# Tasks

## 1. La preferencia

- [x] 1.1 `PreferenciaDeLectura` con los seis campos y sus rangos
- [x] 1.2 Una sola clave en `Almacenamiento`, en JSON
- [x] 1.3 Leida con **cinco segundos** de plazo, como la de las palabras de Jesus
- [x] 1.4 Campo a campo: uno malo no tira los buenos; verificar
- [x] 1.5 Un numero fuera de rango se **acota**, no se descarta; verificar
- [x] 1.6 Sin nada guardado, los recomendados, y **no** se escribe nada; verificar

## 2. La tipografia

- [x] 2.1 El texto de lectura usa el tamano de la preferencia, y no un 16 escrito; verificar
- [x] 2.2 El alto de linea sale de la preferencia, y no del 1,7 del `copyWith`; verificar
- [x] 2.3 El espaciado se aplica; verificar
- [x] 2.4 El **campo de texto** se queda en 16 px aunque la preferencia baje de 16; verificar
- [x] 2.5 "Restaurar valores" lo pone todo a los recomendados en una pulsacion; verificar

## 3. Los tres temas

- [x] 3.1 Claro, sepia y oscuro, con el claro siendo el que hay; verificar
- [x] 3.2 Las nueve combinaciones de cada uno, con el contraste **medido**; verificar
- [x] 3.3 El rojo de las palabras de Jesus cambia en el oscuro, y se mide; verificar
- [x] 3.4 El tema se aplica a **toda** la aplicacion; verificar

## 4. Comodidad

- [x] 4.1 El atenuador, de 1,0 a 0,4, por debajo de las hojas; verificar
- [x] 4.2 La linea enfocada, de 1, 3 o 5 lineas, con el alto derivado del texto; verificar
- [ ] 4.3 Los puntos silabicos, **solo en espanol**, y con reglas de espanol
- [-] 4.4 Y **NO** se cuenta como terminado: el unico modulo de este catalogo es el KJV, que
      esta en ingles, y hace falta uno en espanol para probarlo

## 5. Donde se tocan

- [x] 5.1 Un boton de formato en la cabecera del panel, que es el `Formato` de Logos
- [x] 5.2 Y el orden de dentro: tamano, alto de linea, espaciado, separador, tema, restaurar

## 6. Y LO QUE FALTA DE ESTA TAREA

- [ ] 6.1 La **linea enfocada** esta en la hoja y se guarda, pero **no** se dibuja sobre el
      texto: falta el widget que sigue la linea de lectura
- [ ] 6.2 Los puntos silabicos:Rules de silabeacion del espanol, y pruebas
- [ ] 6.3 El ajuste de tamano de letra **no** llega a la columna de lectura de la pantalla de
      busqueda, que sigue con el tamaño del tema

## 7. Lo que no se copia de `aletheia`

- [-] 7.1 La tipografia descargada: aqui los bytes son bytes de descarga con datos moviles
- [-] 7.2 El TTS y el wake lock, que son changes propios

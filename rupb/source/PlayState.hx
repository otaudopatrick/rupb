package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.FlxState;
import flixel.tile.FlxTilemap;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup;
import flixel.FlxCamera;
import flixel.addons.display.FlxZoomCamera;

import flixel.addons.editors.ogmo.FlxOgmoLoader;

//ARRUMAR SPRITE DA CAVEIRA
//ARRUMAR PULO NA BOX
//ARRUMAR espadada para baixo
//ARRUMAR fundo com bug
//ADICIONAR CORAÇÃO no HUD
//ADICIONAR SPRITE DE MORTE
//ADICIONAR SPRITE DE DANO
//ADICIONAR FIM DA FASE
//ADICIONAR VOCE MORREU MENU
//ADICIONAR CAVEIRA RAPIDA
//ARRUMAR IMPLEMENTAÇÃO DA ESCADA
//IMPLEMENTAR CORREIO
class PlayState extends FlxState{
	var _player:Player;
	var _map:FlxOgmoLoader;
	var _walls:FlxTilemap;
	var _bk:FlxTilemap;
	var _bkColor:FlxTilemap;
	var _escadas2: Array<FlxPoint>;
	var _grpBox: FlxTypedGroup<Box>;
	var _grpCoin: FlxTypedGroup<Coin>;
	var _grpWater: FlxTypedGroup<Water>;
	var _grpSkeleton: FlxTypedGroup<Skeleton>;
	var _grpRock: FlxTypedGroup<Rock>;
	var sword: Sword;
	var _hud:HUD;
	var _money:Int = 0;
	var _health:Int = 3;
	var _zoomCam:FlxZoomCamera;
	var flashAux: Bool = true;

	public static inline var ESCADA = 20;

	override public function create():Void { 
		_player = new Player(0, 0, this);

		_map = new FlxOgmoLoader(AssetPaths.room_002__oel);
		//Carrega os layers do mapa
		_walls = _map.loadTilemap(AssetPaths.tiles__png, 16, 16, "walls");
		_bk = _map.loadTilemap(AssetPaths.tiles__png, 16, 16, "bk");
		_bkColor = _map.loadTilemap(AssetPaths.tiles__png, 16, 16, "color");
		
		_walls.follow();

		_walls.setTileProperties(92, FlxObject.NONE); //Não colidir com escada
		_walls.setTileProperties(109, FlxObject.NONE); //Escada inicio
		_walls.setTileProperties(75, FlxObject.NONE); //Escada fim

		_escadas2 = _walls.getTileCoords(109, false); //Isso é uma gambiarra, precisa ser arrumado
		gambiArrumaY();


		_grpBox = new FlxTypedGroup<Box>();
		_grpCoin = new FlxTypedGroup<Coin>();
		_grpWater = new FlxTypedGroup<Water>();
		_grpSkeleton = new FlxTypedGroup<Skeleton>();
		_grpRock = new FlxTypedGroup<Rock>();
		sword = new Sword();
		_hud = new HUD();
		
		//https://opengameart.org/content/a-platformer-in-the-forest

		//Colocar o jogador e as outras coisas no lugar certo do mapa
		_map.loadEntities(placeEntities, "entity");

		//var sprite = new FlxSprite(_player.x +, _player.y);
		//sprite.makeGraphic(16, 16, FlxColor.BLUE);

		add(_bkColor);
		add(_bk);
		add(_walls);
		add(_player);
		add(_grpBox);
		add(_grpCoin);
		add(sword);
		add(_hud);
		add(_grpWater);
		add(_grpSkeleton);
		add(_grpRock);

		//Cria uma camera para zoom
		var cam:FlxCamera = FlxG.camera;
		_zoomCam = new FlxZoomCamera(Std.int(cam.x), Std.int(cam.y), cam.width, cam.height, cam.zoom);
		_zoomCam.follow(_player, NO_DEAD_ZONE, 3);
 
		FlxG.cameras.reset(_zoomCam);

		FlxG.camera.setScrollBoundsRect(0, 0, _map.width, _map.height);

		FlxG.fullscreen = true;
		
		super.create();
	}

	function punch():Void {
        var _mouse:Bool = FlxG.mouse.justPressed ? true : false;
        var side = _player.movimentSide ? 16 : -16;
        if(_mouse){
			_player.animation.play("SLASH");
			//O jogador é mais alto que o bloco, sempre quebrando o bloco de cima primeiro
			//Diminuir a diferença do Y
            sword.attackFront(_player.last, side);
			FlxG.log.add(sword.last);
			FlxG.overlap(sword, _grpBox, playerAttackBox);
			//Se matar, colocar um esqueleto morto no lugar. 
			FlxG.overlap(sword, _grpSkeleton, playerAttackBox); 
        }
    }
	
	//Mover essa função para a classe player o quanto antes
	function climbing(){
		//Log.trace(_player.last);
		//FlxG.log.add(_player.last);
		var verificador = false;

        if(_player.x == _escadas2[0].x && _player.y - _escadas2[0].y >= 0) //Verifica se o jogador esta na mesma posição da primeira escada
			verificador = true;
		else if(_player.x == _escadas2[1].x && _player.y - _escadas2[1].y >= 0 && _player.y <= 330) //Verifica se o jogador esta na escada dois
			verificador = true;

		else if(_player.x == _escadas2[2].x && _player.y - _escadas2[2].y >= 0 && _player.y <= 224) //verifica se o jogador esta na escada 3 com a altura certa
			verificador = true;
		
		if(verificador){ //Se uma das teclas pressionadas o jogador sobe
			_player.acceleration.y = 0;
			_player.animation.play("CLIMB");
			var _cima = FlxG.keys.anyPressed([UP, W]);
			var _baixo = FlxG.keys.anyPressed([DOWN, S]);
			var _mouse = FlxG.mouse.justPressed;

			var velocidade = 200;

			if(_cima)
				_player.velocity.y = - velocidade;
			else if(_baixo)
				_player.velocity.y = velocidade *2;
			else if(_mouse){
				_player.velocity.y = - velocidade;
			}
		}
		else{ //Retornar gravidade
			_player.acceleration.y = 1000;
		}    
    }

	function placeEntities(entityName:String, entityData:Xml):Void{
		var x:Int = Std.parseInt(entityData.get("x"));
		var y:Int = Std.parseInt(entityData.get("y"));
		
		if(entityName == "player"){
			_player.x = x;
			_player.y = y;
		}
		else if(entityName == "coin"){
			var box = new Coin(x, y);
			_grpCoin.add(box);
		}
		else if(entityName == "box"){
			_grpBox.add(new Box(x, y));
		}
		else if(entityName == "water"){
			_grpWater.add(new Water(x, y));
		}
		else if(entityName == "skeleton"){
			_grpSkeleton.add(new Skeleton(x, y, FlxG.random.bool()));
		}
		else if(entityName == "rock"){
			_grpRock.add(new Rock(x, y + 7)); //Pedra se ajustar ao cenário
		}
	}

	//O y do personagem decresce no mapa, enquanto o y do mapa aumenta
	//A função a seguir arruma o y das escadas de acordo com o y desejado para a função
	//funcionar
	//Mover essa função para classe player
	function gambiArrumaY() {
		_escadas2[0].y = 337;
		_escadas2[1].y = 225;
		_escadas2[2].y = 113;
	}

	public function allColisions() {
		FlxG.collide(_player, _walls); //Colisão
		FlxG.collide(_player, _grpBox);
		FlxG.collide(_grpBox, _walls);
		FlxG.collide(_player, _grpRock);
		FlxG.collide(_grpSkeleton, _walls);
		FlxG.collide(_grpSkeleton, _grpBox);
		FlxG.collide(_grpSkeleton, _grpRock);
	}

	public function zoom() {
		if (FlxG.keys.justPressed.ONE) _zoomCam.targetZoom += -0.25; // zoom in
        if (FlxG.keys.justPressed.TWO) _zoomCam.targetZoom += 0.25; // zoom out
	}

	public function allOverlaps() {
		FlxG.overlap(_player, _grpCoin, getCoin);
		FlxG.overlap(_player, _grpWater, waterLetter);
		FlxG.overlap(_player, _grpSkeleton, playerHurts);
	}

	override public function update(elapsed:Float):Void{
		super.update(elapsed);

		zoom();

		allColisions();
		climbing();
		punch();
		allOverlaps();

		if(!_player.alive) //Colocar mensagem que você morreu, etc...
			FlxG.switchState(new MenuState());
	}
	/**
	Apenas um hurt faria com que o jogador morresse instaneamente
	O timer faz com que o jogador leve dano apenas após 0.3 segundos
	O hud é atualizado, porem. Caso a vida chegue a 0, o timer não é
	acionado.
	 */
	function playerHurts(P: Player, S: Skeleton){
		if(P.alive && P.exists  && S.alive && S.exists){
			
			//P.solid = true;
			var life = Std.int(_player.health - 1);
			_hud.updateHUD(life, _money);
			//Colocar sprite do jogador brilhando aqui, ou recebendo dano
			if(flashAux){
				FlxG.camera.flash();
				flashAux = false;
			}
			if(life == 0){ 
				P.hurt(1);
			}
			else{
				FlxG.camera.shake(1);
				P.timer.start(0.3, function(Timer:FlxTimer){
				P.hurt(1);
				flashAux = true;
			});
			}
		}
	}
	function waterLetter(P: Player, W: Water): Void {
		if(P.alive && P.exists  && W.alive && W.exists){
			P.kill();
		}
	}

	function getCoin(P: Player, C: Coin): Void {
		if(P.alive && P.exists && C.alive && C.exists){
			C.kill();
			_money++;
			_hud.updateHUD(Std.int(_player.health), _money);
		}
	}

	function playerAttackBox(S: Sword, box: FlxObject): Void{
		//var _mouse = FlxG.mouse.justPressed;

		if(S.alive && S.exists && box.alive && box.exists){
			box.kill();
		}
		sword.kill();
	}
}

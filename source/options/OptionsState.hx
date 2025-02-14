package options;

import states.MainMenuState;
import backend.StageData;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import lime.app.Application;
import flixel.input.mouse.FlxMouseEvent;
import flixel.FlxSprite;
import states.MainMenuState;

class OptionsState extends MusicBeatState
{
    var options:Array<String> = [
        'Change Note Colors',
        #if mobile 'Mobile Controls', #end
        'Keyboard Controls',
        'Adjust Delay and Combo',
        'Graphics',
        'Visuals',
        'Psych Gameplay',
        'MintRain Gameplay'
        #if mobile ,'Mobile Options' #end
        #if TRANSLATIONS_ALLOWED , 'Psych Language' #end
    ];
    private var grpOptions:FlxTypedGroup<FlxText>;
    private static var curSelected:Int = 0;
    public static var menuBG:FlxSprite;
    public static var onPlayState:Bool = false;

    private var highlightBox:FlxSprite;
    private var selectorLeft:FlxText;
    private var selectorRight:FlxText;
    private var scrollingBG:FlxBackdrop;

    private var optionImages:Map<String, String>;
    private var currentImage:FlxSprite;

    private var allowMouse:Bool = true;
    private var mouseSelected:Int = -1;
    private var optionBackgrounds:FlxTypedGroup<FlxSprite>;

    private var lastClickTime:Float = 0;
    private var clickCount:Int = 0;

    // 声明 exiting 变量
    private var exiting:Bool = false;

    override function create()
    {
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Options Menu", null);
        #end

        // 只保留一个鼠标显示的代码
        FlxG.mouse.visible = true;

        // 选项背景
        optionBackgrounds = new FlxTypedGroup<FlxSprite>();
        add(optionBackgrounds);

        // 背景
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.color = 0xFFea71fd;
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        // 网格背景
        scrollingBG = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
        scrollingBG.velocity.set(-40, 40);
        add(scrollingBG);

        // 版本信息
        var mreVer:FlxText = new FlxText(12, FlxG.height - 64, 0, "MintRain Engine v" + MainMenuState.mintrainEngineVersion, 12);
        mreVer.scrollFactor.set();
        mreVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(mreVer);
        var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + MainMenuState.psychEngineVersion, 12);
        psychVer.scrollFactor.set();
        psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(psychVer);
        var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v0.2.8", 12);
        fnfVer.scrollFactor.set();
        fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(fnfVer);

        // 高亮框
        highlightBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
        highlightBox.alpha = 0.4;
        add(highlightBox);

        // 选项文字
        grpOptions = new FlxTypedGroup<FlxText>();
        add(grpOptions);

        // 初始化选项
        var optionStartY = (FlxG.height - (options.length * 60)) / 2;

        for (num => option in options)
        {
            // 创建文字
            var optionText = new FlxText(60, optionStartY + num * 60 + 10, 0, Language.getPhrase('options_$option', option), 32);
            optionText.setFormat("assets/fonts/arturito-slab.ttf", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            optionText.borderSize = 2;
            grpOptions.add(optionText);

            // 创建背景，宽度与选项文字匹配
            var background = new FlxSprite(50, optionStartY + num * 60);
            background.makeGraphic(Std.int(optionText.width + 40), 50, FlxColor.fromRGB(0, 0, 0, 128)); // 宽度根据文字宽度动态调整
            background.alpha = 0.5;
            optionBackgrounds.add(background);

            // 确保背景不超出屏幕
            if (background.x + background.width > FlxG.width) {
                background.x = FlxG.width - background.width - 10; // 留出 10 像素的边距
            }
        }

        // 选择器箭头
        selectorLeft = new FlxText(0, 0, 0, '>', 32);
        selectorLeft.setFormat("assets/fonts/arturito-slab.ttf", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        selectorLeft.borderSize = 2;
        add(selectorLeft);
        
        selectorRight = new FlxText(0, 0, 0, '<', 32);
        selectorRight.setFormat("assets/fonts/arturito-slab.ttf", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        selectorRight.borderSize = 2;
        add(selectorRight);

        // 选项图片系统
        optionImages = [
            'Change Note Colors' => 'OptionsUI/001',
            'Mobile Controls' => 'OptionsUI/009',
            'Keyboard Controls' => 'OptionsUI/002',
            'Adjust Delay and Combo' => 'OptionsUI/003',
            'Graphics' => 'OptionsUI/004',
            'Visuals' => 'OptionsUI/005',
            'Psych Gameplay' => 'OptionsUI/006',
            'MintRain Gameplay' => 'OptionsUI/007',
            'Mobile Options' => 'OptionsUI/010',
            'Psych Language' => 'OptionsUI/008'
        ];

        currentImage = new FlxSprite(FlxG.width - 200, 0);
        currentImage.alpha = 0;
        add(currentImage);

        changeSelection();
        ClientPrefs.saveSettings();

        addTouchPad('UP_DOWN_SIDERIGHT', 'A_B');
        super.create();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (!exiting && allowMouse)
        {
            var mouseX = FlxG.mouse.x;
            var mouseY = FlxG.mouse.y;
            var foundHover = false;

            // 鼠标区域检测
            for (num => background in optionBackgrounds.members)
            {
                if (mouseX >= background.x && 
                    mouseX <= background.x + background.width &&
                    mouseY >= background.y && 
                    mouseY <= background.y + background.height)
                {
                    foundHover = true;
                    handleHover(num);
                    handleClicks(num);
                    break;
                }
            }

            if (!foundHover && mouseSelected != -1)
            {
                mouseSelected = -1;
                FlxG.sound.play(Paths.sound('scrollMenu'));
            }
        }

        // 键盘控制
        if (!exiting)
        {
            if (controls.UI_UP_P) changeSelection(-1, false);
            if (controls.UI_DOWN_P) changeSelection(1, false);
            
            if (controls.BACK)
            {
                exiting = true;
                FlxG.sound.play(Paths.sound('cancelMenu'));
                if(onPlayState)
                {
                    StageData.loadDirectory(PlayState.SONG);
                    LoadingState.loadAndSwitchState(new PlayState());
                    FlxG.sound.music.volume = 0;
                }
                else MusicBeatState.switchState(new MainMenuState());
            }
            else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
        }
    }

    function handleHover(num:Int)
    {
        if (mouseSelected != num)
        {
            mouseSelected = num;
            changeSelection(num - curSelected, true);
        }
    }

    function handleClicks(num:Int)
    {
        if (FlxG.mouse.justPressed)
        {
            var currentTime = Date.now().getTime();
            if (currentTime - lastClickTime < 1000)
            {
                if (++clickCount >= 2)
                {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    openSelectedSubstate(options[num]);
                    clickCount = 0;
                }
            }
            else
            {
                clickCount = 1;
            }
            lastClickTime = currentTime;

            // 直接载入所选的 state
            openSelectedSubstate(options[num]);
        }
    }

    function changeSelection(change:Int = 0, isMouseSelection:Bool = false)
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

        for (num => item in grpOptions.members)
        {
            item.alpha = 0.6;
            if (num == curSelected)
            {
                item.alpha = 1;
                
                var targetY = item.y - 4;
                FlxTween.cancelTweensOf(selectorLeft);
                FlxTween.cancelTweensOf(selectorRight);

                if (isMouseSelection) {
                    FlxTween.tween(selectorLeft, { alpha: 0 }, 0.2, { ease: FlxEase.quadOut });
                    FlxTween.tween(selectorRight, { alpha: 0 }, 0.2, { ease: FlxEase.quadOut });
                } else {
                    FlxTween.tween(selectorLeft, { alpha: 1, x: item.x - 40, y: targetY }, 0.3, { ease: FlxEase.bounceOut });
                    FlxTween.tween(selectorRight, { alpha: 1, x: item.x + item.width + 10, y: targetY }, 0.3, { ease: FlxEase.bounceOut });
                }

                FlxTween.cancelTweensOf(highlightBox);
                highlightBox.visible = true;
                FlxTween.tween(highlightBox, {
                    x: item.x - 20,
                    y: item.y - 8,
                    "scale.x": item.width + 40,
                    "scale.y": item.height + 16
                }, 0.25, { ease: FlxEase.bounceOut, onUpdate: function(twn:FlxTween) { highlightBox.updateHitbox(); } });

                var selectedOption = options[curSelected];
                if (optionImages.exists(selectedOption))
                {
                    var imagePath = optionImages.get(selectedOption);
                    trace('Loading image: $imagePath');

                    FlxTween.tween(currentImage, { x: FlxG.width, alpha: 0 }, 0.15, {
                        onComplete: function(twn:FlxTween) {
                            currentImage.loadGraphic(Paths.image(imagePath));
                            currentImage.x = FlxG.width;
                            currentImage.y = (FlxG.height - currentImage.height) / 2;
                            currentImage.alpha = 0;

                            FlxTween.tween(currentImage, { x: FlxG.width - 500, alpha: 1 }, 0.3);
                        }
                    });
                }
            }
        }
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }

    function openSelectedSubstate(label:String) {
        if (label != "Adjust Delay and Combo"){
            removeTouchPad();
            persistentUpdate = false;
        }
        switch(label)
        {
            case 'Change Note Colors':
                openSubState(new options.NotesColorSubState());
            case 'Mobile Controls':
                    persistentUpdate = false;
                    openSubState(new mobile.substates.MobileControlSelectSubState());
            case 'Keyboard Controls':
                openSubState(new options.ControlsSubState());
            case 'Graphics':
                openSubState(new options.GraphicsSettingsSubState());
            case 'Visuals':
                openSubState(new options.VisualsSettingsSubState());
            case 'Psych Gameplay':
                openSubState(new options.GameplaySettingsSubState());
            case 'MintRain Gameplay':
                openSubState(new options.ArchivedGameplaySettingSubState());
            case 'Adjust Delay and Combo':
                MusicBeatState.switchState(new options.NoteOffsetState());
            case 'Mobile Options':
                openSubState(new mobile.options.MobileOptionsSubState());
            case 'Psych Language':
                openSubState(new options.LanguageSubState());
        }
    }

    override function closeSubState()
    {
        super.closeSubState();
        ClientPrefs.saveSettings();
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Options Menu", null);
        #end
        controls.isInSubstate = false;
        removeTouchPad();
        addTouchPad('UP_DOWN_SIDERIGHT', 'A_B');
        persistentUpdate = true;
    }

    override function destroy()
    {
        ClientPrefs.loadPrefs();
        super.destroy();
    }
}
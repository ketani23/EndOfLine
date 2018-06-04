// WorldObjectController.js
// Version: 0.0.1
// Event: Lens Initialized

//@input bool useGroundGrid
//@input Asset.Material touchCollisionMaterial
//@input SceneObject groundGrid
//@input Component.Camera cam

//@input Component.SpriteVisual intro
//@input Component.SpriteVisual cc
//@input Asset.Material blueMat
//@input Asset.Material yellowMat
//@input Asset.Material pinkMat
//@input Component.MeshVisual gridVFXPlane

//@input SceneObject yellowHeadParent
//@input Asset.Material PBRtriangle_Yellow
//@input Asset.Material seeThruTri_Yellow
//@input Asset.Material PBRscanline_Yellow

//@input SceneObject pinkHeadParent
//@input Asset.Material PBRtriangle_Pink
//@input Asset.Material seeThruTri_Pink
//@input Asset.Material PBRscanline_Pink

//@input Asset.Material grid_vfx_yellow
//@input Asset.Material grid_vfx_pink

//@input Asset.Material yellowArrowsMat
//@input Asset.Material pinkArrowsMat

//@input Component.MeshVisual yellowArrows
//@input Component.MeshVisual pinkArrows

//@input Component.AudioComponent musicPlayer

//@input Asset.AudioTrackAsset correctConn
//@input Asset.AudioTrackAsset levelCompleted
//@input Asset.AudioTrackAsset tapOnConn

//@input SceneObject cell_1_1
//@input SceneObject cell_2_1
//@input SceneObject cell_2_2
//@input SceneObject cell_3_1
//@input SceneObject cell_3_2
//@input SceneObject cell_3_3
//@input SceneObject cell_3_4
//@input SceneObject cell_3_5
//@input SceneObject cell_4_1
//@input SceneObject cell_4_2
//@input SceneObject cell_4_3
//@input SceneObject cell_4_4
//@input SceneObject cell_5_1
//@input SceneObject cell_5_2
//@input SceneObject cell_5_3
//@input SceneObject cell_5_4
//@input SceneObject cell_5_5
//@input SceneObject cell_6_1
//@input SceneObject cell_6_2
//@input SceneObject cell_6_3
//@input SceneObject cell_6_4
//@input SceneObject cell_7_1
//@input SceneObject cell_7_2
//@input SceneObject cell_7_3
//@input SceneObject cell_7_4
//@input SceneObject cell_7_5
//@input SceneObject cell_8_1
//@input SceneObject cell_8_2
//@input SceneObject cell_9_1

//@input Asset.RenderMesh gate00
//@input Asset.RenderMesh gate01
//@input Asset.RenderMesh gate02
//@input Asset.RenderMesh gate_glow_00
//@input Asset.RenderMesh gate_glow_01
//@input Asset.RenderMesh gate_glow_02

//@input Component.SpriteVisual score0
//@input Component.SpriteVisual score10
//@input Component.SpriteVisual score100

//@input Asset.Texture zero
//@input Asset.Texture one
//@input Asset.Texture two
//@input Asset.Texture three
//@input Asset.Texture four
//@input Asset.Texture five
//@input Asset.Texture six
//@input Asset.Texture seven
//@input Asset.Texture eight
//@input Asset.Texture nine

//@input SceneObject scoreLevel
//@input Asset.Texture scoreRectifier
//@input Asset.Texture scoreRecognizer
//@input Asset.Texture scoreSailer
//@input Asset.Texture scoreMaster

//@input SceneObject endScreen

self.started = false;
self.audioPlayer = script.getSceneObject().getFirstComponent("Component.AudioComponent");
self.pathFound = false;
self.yellowCount = 0;
self.pinkCount = 0;
self.timerStarted = false;
self.timeOfStart = 0;
self.gameScore = 0;
self.gameEnded = false;

var cells = [self.cell_1_1,
self.cell_2_1,
self.cell_2_2,
self.cell_3_1,
self.cell_3_2,
self.cell_3_3,
self.cell_3_4,
self.cell_3_5,
self.cell_4_1,
self.cell_4_2,
self.cell_4_3,
self.cell_4_4,
self.cell_5_1,
self.cell_5_2,
self.cell_5_3,
self.cell_5_4,
self.cell_5_5,
self.cell_6_1,
self.cell_6_2,
self.cell_6_3,
self.cell_6_4,
self.cell_7_1,
self.cell_7_2,
self.cell_7_3,
self.cell_7_4,
self.cell_7_5,
self.cell_8_1,
self.cell_8_2,
self.cell_9_1];

var list = [];
var permList = [];

var START = self.cell_1_1;
var END = self.cell_9_1;

// If an object with a touch component is defined then this will allow the user to double tap through them to 
// perform a camera swap from back to front cam
if(script.getSceneObject().getComponentCount("Component.TouchComponent") > 0)
{
    //script.getSceneObject().getFirstComponent("Component.TouchComponent").addTouchBlockingException("TouchTypeDoubleTap");
}
global.touchSystem.touchBlocking = true;


// Hides the ground grid if the option is chosen to do so
if(!script.useGroundGrid && script.groundGrid)
{   
    script.groundGrid.enabled = false;    
}

// Hides the touchCollision object when lens is running by setting the alpha on its material to 0
if(script.touchCollisionMaterial)
{
    script.touchCollisionMaterial.mainPass.baseColor = new vec4(1,1,1,0);
}

// Event and callback setup  
function onSurfaceReset(eventData)
{
    //script.getSceneObject().getTransform().setLocalPosition(new vec3(0, 0, 0));
}
var worldTrackingResetEvent = script.createEvent("WorldTrackingResetEvent");
worldTrackingResetEvent.bind(onSurfaceReset);

function onTurnOnEvent(eventData)
{
    initialize();
}
var turnOnEvent = script.createEvent("TurnOnEvent");
turnOnEvent.bind(onTurnOnEvent);

function onFrontCamEvent(eventData)
{
    for(var i = 0; i < script.getSceneObject().getChildrenCount(); i++)
    {
        var childObject = script.getSceneObject().getChild(i);
        if(childObject)
        {
            childObject.enabled = false;
        }
    }        
}
var cameraFrontEvent = script.createEvent("CameraFrontEvent");
cameraFrontEvent.bind(onFrontCamEvent);

function onBackCamEvent(eventData)
{
    for(var i = 0; i < script.getSceneObject().getChildrenCount(); i++)
    {
        var childObject = script.getSceneObject().getChild(i);
        if(childObject)
        {
            childObject.enabled = true;                   
        }
    }
    if(!script.useGroundGrid && script.groundGrid)
    {
        script.groundGrid.enabled = false;
    }  
}
var cameraBackEvent = script.createEvent("CameraBackEvent");
cameraBackEvent.bind(onBackCamEvent);

function onUpdateEvent(eventData)
{
    if(self.timerStarted)
        setTimer();
}
var updateEvent = script.createEvent("UpdateEvent");
updateEvent.bind(onUpdateEvent);

var rowLims = [0,2,7,11,16,20,25,27];
function initialize()
{
    for(var i=0; i<29; i++)
    {
        if(i == 0)
        {
            cells[i].getTransform().setLocalRotation(quat.fromEulerVec(new vec3(0, -60 * 0.0174533, 0)));
            cells[i].getChild(1).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial = script.yellowMat;
        }
        else if(i == 28)
        {
            cells[i].getTransform().setLocalRotation(quat.fromEulerVec(new vec3(0, 0, 0)));
            cells[i].getChild(1).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial = script.pinkMat;
        }
        else
        {
            cells[i].getTransform().setLocalRotation(quat.fromEulerVec(new vec3(0, 60 * 0.0174533, 0)));
            cells[i].getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial = script.blueMat;
        }
    }

    for(var i=1;i<9;i++)
    {
        for(var j=rowLims[i-1] + 2;j<rowLims[i];j++)
        {
            var val = Math.random()*10;
            if(val<2)
            {
                cells[j].getFirstComponent("Component.MeshVisual").mesh = self.gate00;
                cells[j].getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mesh = self.gate_glow_00;
                cells[j].getChild(0).getTransform().setLocalPosition(new vec3(0,0,-54));
                cells[j].getChild(1).getTransform().setLocalPosition(new vec3(0,0,54));
            }
            else if(val>=2 && val <6)
            {
                cells[j].getFirstComponent("Component.MeshVisual").mesh = self.gate01;
                cells[j].getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mesh = self.gate_glow_01;
                cells[j].getChild(0).getTransform().setLocalPosition(new vec3(-45,0,-27));
                cells[j].getChild(1).getTransform().setLocalPosition(new vec3(0,0,-54));
            }
            else
            {
                cells[j].getFirstComponent("Component.MeshVisual").mesh = self.gate02;
                cells[j].getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mesh = self.gate_glow_02;
                cells[j].getChild(0).getTransform().setLocalPosition(new vec3(-45,0,-27));
                cells[j].getChild(1).getTransform().setLocalPosition(new vec3(45,0,-27));
            }
        }
    }
}

function setTimer()
{
    var time = getTime() - self.timeOfStart;
    time = Math.floor(time);
    if(time<1000)
    {
        self.gameScore = time;
        var score100 = Math.floor(time/100);
        var score10 = Math.floor((time - score100*100)/10);
        var score0 = time%10;
        setSprite(self.score100, score100);
        setSprite(self.score10, score10);
        setSprite(self.score0, score0);
    }
}

function setSprite(sprite, val)
{
    if(val == 0){
        sprite.mainMaterial.mainPass.baseTex = self.zero;
    }
    else if(val == 1){
        sprite.mainMaterial.mainPass.baseTex = self.one;
    }
    else if(val == 2){
        sprite.mainMaterial.mainPass.baseTex = self.two;
    }
    else if(val == 3){
        sprite.mainMaterial.mainPass.baseTex = self.three;
    }
    else if(val == 4){
        sprite.mainMaterial.mainPass.baseTex = self.four;
    }
    else if(val == 5){
        sprite.mainMaterial.mainPass.baseTex = self.five;
    }
    else if(val == 6){
        sprite.mainMaterial.mainPass.baseTex = self.six;
    }
    else if(val == 7){
        sprite.mainMaterial.mainPass.baseTex = self.seven;
    }
    else if(val == 8){
        sprite.mainMaterial.mainPass.baseTex = self.eight;
    }
    else if(val == 9){
        sprite.mainMaterial.mainPass.baseTex = self.nine;
    }
}

if(!self.started)
{
    function onTapFirst(eventData)
    {
        if(!self.started)
        {
            script.intro.enabled = false;
            script.intro.getSceneObject().enabled = false;
            script.cc.enabled = true;
            self.started = true;
        }
        else
        {
            if(!self.gameEnded)
            {
                if(!self.timerStarted){
                   self.timeOfStart = getTime();
                   self.timerStarted = true;
                }
                var tapPos = eventData.getTapPosition();
                self.audioPlayer.audioTrack = script.tapOnConn;
                self.audioPlayer.play(1);
                checkTap(tapPos);
            }
            else
            {
                script.intro.enabled = true;
                script.intro.getSceneObject().enabled = true;
                self.started = false;
                self.pathFound = false;
                self.yellowCount = 0;
                self.pinkCount = 0;
                self.timerStarted = false;
                self.timeOfStart = 0;
                self.gameScore = 0;
                self.gameEnded = false;
                self.gridVFXPlane.mainMaterial.mainPass.baseTex.control.stop();
                self.musicPlayer.stop(true);
                replaceHeadMats(self.yellowHeadParent, self.PBRtriangle_Yellow, self.seeThruTri_Yellow, self.PBRscanline_Yellow);
                replaceHeadMats(self.pinkHeadParent, self.PBRtriangle_Pink, self.seeThruTri_Pink, self.PBRscanline_Pink);
                self.yellowArrows.mainMaterial = self.yellowArrowsMat;
                self.pinkArrows.mainMaterial = self.pinkArrowsMat;
                self.yellowArrows.getTransform().setLocalRotation(quat.fromEulerVec(new vec3(90 * 0.0174533, 0, 180 * 0.0174533)));
                self.pinkArrows.getTransform().setLocalRotation(quat.fromEulerVec(new vec3(-90 * 0.0174533, 0, 0)));
                global.tweenManager.resetObject(script.scoreLevel, "ScoreTween");
                global.tweenManager.resetObject(script.endScreen, "EndAlphaTween");
                initialize();
            }
        }
    }
    var tapEvent = script.createEvent("TapEvent");
    tapEvent.bind(onTapFirst);
}

function checkTap(tapPos)
{
    var min = 1000;
    var minIndex = -1;
    for(var i = 0; i < 29; i++)
    {
        var dist = tapPos.distance(self.cam.worldSpaceToScreenSpace(cells[i].getTransform().getWorldPosition()));
        if(dist < min)
        {
            min = dist;
            minIndex = i;
        }
    }
    if(minIndex != -1)
    {
        if(minIndex == 0) //START
        {
            var oldRot = cells[minIndex].getTransform().getWorldRotation().toEuler();
            if(oldRot.y > 4.5)
            {
                var angle = -60;
            }
            else
            {
                var angle = 60;
            }
            cells[minIndex].getTransform().setWorldRotation(quat.fromEulerVec(oldRot.add(new vec3(0, angle * 0.0174533, 0))));
        }
        else if(minIndex == 28) //END
        {
            var oldRot = cells[minIndex].getTransform().getWorldRotation().toEuler();
            if(oldRot.y < 1.5)
            {
                var angle = 60;
            }
            else
            {
                var angle = -60;
            }
            cells[minIndex].getTransform().setWorldRotation(quat.fromEulerVec(oldRot.add(new vec3(0, angle * 0.0174533, 0))));
        }
        else
        {
            var oldRot = cells[minIndex].getTransform().getWorldRotation().toEuler();
            cells[minIndex].getTransform().setWorldRotation(quat.fromEulerVec(oldRot.add(new vec3(0,60 * 0.0174533,0))));
        }
    }
    checkPath(START);
    if(!self.pathFound)
        checkPath(END);
}

function checkPath(startNode)
{
    var nextNode = findNext(startNode.getFirstComponent("Component.ScriptComponent").api.node1, startNode);
    list = [];
    if(nextNode == null)
        resetAll(startNode);
    while(nextNode != null)
    {
        if(nextNode.getParent().getChild(2).getChild(0).getComponentCount("Component.MeshVisual")>0){
            if(startNode.name == START.name){
                nextNode.getParent().getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial = script.yellowMat;
                self.yellowCount++;
            }
            else{
                nextNode.getParent().getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial = script.pinkMat;
                self.pinkCount++;
            }
        }
        addToList(nextNode.getParent());
        list.push(nextNode.getParent());
        var connNode = findConnector(nextNode);
        if(connNode!=null){
            nextNode = findNext(connNode, startNode);
        }
        else{
            if(nextNode.name == END.name){
                if(self.yellowCount<self.pinkCount)
                    break;
                self.gridVFXPlane.mainMaterial = self.grid_vfx_yellow;
                self.gridVFXPlane.mainMaterial.mainPass.baseTex.control.play(-1,0);
                self.musicPlayer.stop(true);
                self.audioPlayer.audioTrack = script.levelCompleted;
                self.audioPlayer.play(1);
                replaceHeadMats(self.pinkHeadParent, self.PBRtriangle_Yellow, self.seeThruTri_Yellow, self.PBRscanline_Yellow);
                self.pinkArrows.mainMaterial = self.yellowArrows.mainMaterial;
                self.pinkArrows.getTransform().setLocalRotation(quat.fromEulerVec(new vec3(-90 * 0.0174533, 180 * 0.0174533, 0)));
                END.getChild(1).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial = self.yellowMat;
                if(self.yellowCount>self.pinkCount)
                    self.pathFound = true;
                self.timerStarted = false;
                setEndGame();
            }
            else{
                self.gridVFXPlane.mainMaterial = self.grid_vfx_pink;
                self.gridVFXPlane.mainMaterial.mainPass.baseTex.control.play(-1,0);
                self.musicPlayer.stop(true);
                self.audioPlayer.audioTrack = script.levelCompleted;
                self.audioPlayer.play(1);
                replaceHeadMats(self.yellowHeadParent, self.PBRtriangle_Pink, self.seeThruTri_Pink, self.PBRscanline_Pink);
                self.yellowArrows.mainMaterial = self.pinkArrows.mainMaterial;
                self.yellowArrows.getTransform().setLocalRotation(quat.fromEulerVec(new vec3(-90 * 0.0174533, 0, 0)));
                START.getChild(1).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial = self.pinkMat;
                self.timerStarted = false;
                setEndGame();
            }
            nextNode = null;
        }
        if(nextNode== null)
        {
            resetAll(startNode);
        }
    }
}

function setEndGame()
{
    setScoreLevel();
    global.tweenManager.startTween(script.scoreLevel, "ScoreTween");
    global.tweenManager.startTween(script.endScreen, "EndAlphaTween");
    self.gameEnded = true;
}

function setScoreLevel()
{
    var sprite = self.scoreLevel.getFirstComponent("Component.SpriteVisual");
    if(self.gameScore >= 200)
        sprite.mainMaterial.mainPass.baseTex = self.scoreRectifier;
    else if( self.gameScore >= 100)
        sprite.mainMaterial.mainPass.baseTex = self.scoreRecognizer;
    else if( self.gameScore >= 20)
        sprite.mainMaterial.mainPass.baseTex = self.scoreSailer;
    else
        sprite.mainMaterial.mainPass.baseTex = self.scoreMaster;
}

function replaceHeadMats(head, PBRtriangle, seeThruTri, PBRscanline)
{
    for(var i = 0; i < head.getChildrenCount(); i++)
    {
        if(i<10)
        {
            head.getChild(i).getFirstComponent("Component.MeshVisual").mainMaterial = PBRtriangle;
        }
        else if(i == 11)
        {
            head.getChild(i).getFirstComponent("Component.MeshVisual").mainMaterial = seeThruTri;
        }
        else if(i == 12)
        {
            head.getChild(i).getFirstComponent("Component.MeshVisual").mainMaterial = PBRscanline;
        }
    }
}

function addToList(node)
{
    for(var i =0; i<permList.length; i++)
    {
        if(permList[i].name == node.name)
            return;
    }
    permList.push(node);
    self.audioPlayer.audioTrack = script.correctConn;
    self.audioPlayer.play(1);
}

function findNext(nn, startNode)
{
    for(var i=1; i<28; i++)
    {
        if(nn.getParent().name != cells[i].name)
        {
            if(cells[i].getComponentCount("Component.ScriptComponent")==0)
                return null;
            var SOscript = cells[i].getFirstComponent("Component.ScriptComponent");
            if(SOscript.api.node1.getTransform().getWorldPosition().distance(nn.getTransform().getWorldPosition()) < 5)
            {
                return SOscript.api.node1;
            }
            if(SOscript.api.node2.getTransform().getWorldPosition().distance(nn.getTransform().getWorldPosition()) < 5)
            {
                return SOscript.api.node2;
            }
            if(END.getFirstComponent("Component.ScriptComponent").api.node1.getTransform().getWorldPosition().distance(nn.getTransform().getWorldPosition()) < 5 && startNode.name != END.name)
                return END;
            if(START.getFirstComponent("Component.ScriptComponent").api.node1.getTransform().getWorldPosition().distance(nn.getTransform().getWorldPosition()) < 5 && startNode.name != START.name)
                return START;
        }
    }
    return null;
}

function findConnector(nn)
{
    if(nn.getParent().getComponentCount("Component.ScriptComponent")==0)
        return null;
    var parentScript = nn.getParent().getFirstComponent("Component.ScriptComponent");
    if(nn.name == parentScript.api.node1.name)
    {
        return parentScript.api.node2;
    }
    else
    {
        return parentScript.api.node1;
    }
}

function resetAll(node)
{
    for(var i = 1; i<28; i++)
    {
        var j = 0
        for(; j<list.length; j++)
        {
            if(cells[i].name == list[j].name)
            {
                break;
            }
        }
        if(j == list.length && cells[i].getChild(2).getChild(0).getComponentCount("Component.MeshVisual")>0){
            if(node.name == START.name && cells[i].getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial.name == script.yellowMat.name)
                cells[i].getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial = script.blueMat;

            if(node.name == END.name && cells[i].getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial.name == script.pinkMat.name)
                cells[i].getChild(2).getChild(0).getFirstComponent("Component.MeshVisual").mainMaterial = script.blueMat;
        }
    }
}
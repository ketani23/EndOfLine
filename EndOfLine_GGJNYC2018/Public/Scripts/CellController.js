// -----JS CODE-----
//@input SceneObject node1
//@input SceneObject node2

self.initialized = false;

if(!self.initialized)
{
	script.node1 = script.getSceneObject().getChild(0);
	if(script.getSceneObject().getChildrenCount()>2)
		script.node2 = script.getSceneObject().getChild(1);

	script.api.node1 = script.node1;
	script.api.node2 = script.node2;

	self.initialized = true;
}
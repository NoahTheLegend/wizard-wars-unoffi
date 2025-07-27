// adds removes support on the current tile

#include "PathingNodesCommon.as";

void onSetStatic(CBlob@ this, const bool isStatic)
{
	this.getShape().SetTileValue_Legacy();
	
	UpdateNearbyNodes(this);
}

void UpdateNearbyNodes(CBlob@ this)
{
	HighLevelNode@[]@ nodeMap;
	CRules@ rules = getRules();
	if (!rules.get("node_map", @nodeMap)) return;

	HighLevelNode@[][]@ queued_node_updates;
	if (!rules.get("queued_node_updates", @queued_node_updates)) return;

	HighLevelNode@[] node_update = getNodesInRadius(this.getPosition(), node_distance * 1.5f, nodeMap);

	queued_node_updates.push_back(node_update);
	
	for (uint i = 0; i < node_update.length; i++)
	{
		queued_node_updates[queued_node_updates.length - 1].insertLast(node_update[i]);
	}
}
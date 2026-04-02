extends RefCounted

func setup_building(building: Building):
	for manuscript: ConsumeResource in Bus.player.manuscripts.values():
		var job: Job = load("uid://clygfq5g2dkq5").dupe()
		job.effects[0].craft_consume = manuscript
		job.description = "Craft %s"%manuscript.card_name
		job.requirements = manuscript.craft_requirements
		building.add_job_container(job)

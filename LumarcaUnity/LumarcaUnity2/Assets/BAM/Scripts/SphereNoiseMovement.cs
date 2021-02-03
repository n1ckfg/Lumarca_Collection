using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SphereNoiseMovement : MonoBehaviour {

	public float range = 0.5f;
	public float speedMod = 0.5f;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {

		float moveTime = Time.realtimeSinceStartup * speedMod;

		transform.position = new Vector3(
			UtilScript.Map(Mathf.PerlinNoise(moveTime, 0), 0, 1, -range, range),
			transform.position.y,
			UtilScript.Map(Mathf.PerlinNoise(0, moveTime), 0, 1, -range, range));
	}
}

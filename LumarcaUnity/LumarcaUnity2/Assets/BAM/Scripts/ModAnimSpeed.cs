using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ModAnimSpeed : MonoBehaviour {

	public Animation myAnim;
	public float speed;
	public string animationName = "Allosaurus_Walk";

	// Use this for initialization
	void Start () {
		print(myAnim);

		Time.timeScale = speed;

		AnimationState aState = myAnim[animationName];

		aState.speed = speed;
	}
	
	// Update is called once per frame
	void Update () {
	}
}

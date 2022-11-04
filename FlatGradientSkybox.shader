Shader "Skybox/DreliasFlatGradientSkybox"
{
	Properties
	{
		_TopColor("Top Color", Color) = (1, 0.3, 0.3, 0)
		_BottomColor("Bottom Color", Color) = (0.3, 0.3, 1, 0)
		_AngleTopColorEnd("Top Color Angle", Range(-90, 90)) = 45
		_AngleBottomColorEnd("Bottom Color Angle", Range(-90, 90)) = 0
		_Steps("Steps", Range(0,45)) = 0
	}
		SubShader
	{
		Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
		Cull Off ZWrite Off

		Pass
		{
			CGPROGRAM

			fixed4 _TopColor, _BottomColor;
			float _AngleTopColorEnd, _AngleBottomColorEnd, _Steps;

			#pragma vertex vert
			#pragma fragment frag

			struct appdata {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};


			struct v2f {
				float4 position : SV_POSITION;
				float4 screenPosition : TEXCOORD0;
			};

			v2f vert(appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.screenPosition = v.texcoord;
				return o;
			}

			float GetFOV()
			{
				return atan(1.0f / unity_CameraProjection._m11);
			}

			sampler2D _MainTex;

			fixed4 frag(v2f i, float4 screenPos : SV_POSITION) : SV_Target
			{
				float3 camForward = -UNITY_MATRIX_V[2].xyz; // Cam forward vector
				float3 camUp = UNITY_MATRIX_V[1].xyz; // Cam up vector

				/* Cam rotation around its forward axis (How much camera "leans left or right") */
				/* Find angle between cam up and cam up if it was rotated by 0° on its z axis */
				float3 flattenedXYForward = normalize(float3(camForward.x, 0, camForward.z));		// Find the forward vector flattened on Y (as if cam looked horizontally)
				float3 flattenedRight = float3(flattenedXYForward.z, 0, -flattenedXYForward.x);		// Deduct right vector
				float3 correctUp = normalize(-cross(flattenedRight, camForward));					// Deduct up vector

				float camZangle = acos(clamp(dot(normalize(camUp), correctUp),-1,1)) * sign(dot(normalize(camUp), flattenedRight));			// Get angle between "up if cam looked horizontally" and actual up
				_Steps *= (3.14 / 180);
				if (_Steps != 0) camZangle = (int)((camZangle + _Steps / 2) / _Steps) * (float)_Steps;

				/* Cam elevation (how much camera "looks up") */
				/* Find angle between cam forward and cam forward without y */
				float3 flattenedForward = normalize(float3(camForward.x, 0, camForward.z));
				float camXangle = acos(dot(normalize(camForward), flattenedForward)) * sign(camForward.y);
				if (_Steps != 0) camXangle = (int)((camXangle + _Steps / 2) / _Steps) * (float)_Steps;

				/* A bit of trigonometry : Get pixel distance from center corresponding to bottom and top angle closest point */
				float a = _ScreenParams.y / 2;
				float alpha = GetFOV();
				float b = a / tan(alpha);	// get side adjacent from known values : fov/2 as angle and pixel qty of screen as opposite side length

				float angleBottomAsPixelDistanceFromCenter = b * tan(camXangle - _AngleBottomColorEnd * (3.14 / 180));
				float angleTopAsPixelDistanceFromCenter = b * tan(camXangle - _AngleTopColorEnd * (3.14 / 180));

				float centerX = _ScreenParams.x / 2;
				float centerY = _ScreenParams.y / 2;

				/* Compute slope of bottom and top horizon colors */
				float coefdir = tan(camZangle); // Tan = sin/cos = how much we raise / how much we advance

				float botKnownPointX = centerX + sin(camZangle) * angleBottomAsPixelDistanceFromCenter;
				float botKnownPointY = centerY - cos(camZangle) * angleBottomAsPixelDistanceFromCenter;
				float botOrdorigin = botKnownPointY - botKnownPointX * coefdir;

				float topKnownPointX = centerX + sin(camZangle) * angleTopAsPixelDistanceFromCenter;
				float topKnownPointY = centerY - cos(camZangle) * angleTopAsPixelDistanceFromCenter;
				float topOrdorigin = topKnownPointY - topKnownPointX * coefdir;

				/* Get color proportion of specific pixel by getting the intercept of slope passing by, and comparing to bottom/top intercepts */
				float pixOrdOrigin = screenPos.y - screenPos.x * coefdir;
				float pixColProportion = clamp((pixOrdOrigin - botOrdorigin) / (topOrdorigin - botOrdorigin),0,1);

				return lerp(_BottomColor,_TopColor,pixColProportion);
			}
			ENDCG
		}
	}
}
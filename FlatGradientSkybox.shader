Shader "Skybox/DreliasFlatGradientSkybox"
{
	Properties
	{
		_TopColor("Top Color", Color) = (1, 0.3, 0.3, 0)
		_BottomColor("Bottom Color", Color) = (0.3, 0.3, 1, 0)
		_AngleTopColorEnd("Top Color Angle", Range(-90, 90)) = 45
		_AngleBottomColorEnd("Bottom Color Angle", Range(-90, 90)) = 0
	}
	SubShader
	{
		Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
		Cull Off ZWrite Off

		Pass
		{
			CGPROGRAM

			fixed4 _TopColor, _BottomColor;
			float _AngleTopColorEnd, _AngleBottomColorEnd;

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
				float t = unity_CameraProjection._m11;
				const float Rad2Deg = 180 / 3.14;
				return atan(1.0f / t) * 2.0 * Rad2Deg;
			}

			sampler2D _MainTex;
			
			fixed4 frag(v2f i, float4 screenPos : SV_POSITION) : SV_Target
			{
				float skyboxScaled = 180 / GetFOV();					// Size of skybox considering screen vertical size is 1
				float camAngle = asin(UNITY_MATRIX_V[2].y) / (1.57);	// From cam forward transform to -100%/100% percentage from -90/90 degrees of camera

			int screenHeight = 1080;

				float angleTopColorEnd = _AngleTopColorEnd / 90; // between -100%/100%
				float angleBottomColorEnd = _AngleBottomColorEnd / 90; // between -100%/100%

				float milieuSkyboxAggrandie = skyboxScaled / 2;			// Horizon coordinates

				float coordTopColor = milieuSkyboxAggrandie + (milieuSkyboxAggrandie * angleTopColorEnd);		// Top gradient coords
				float coordBottomColor = milieuSkyboxAggrandie + (milieuSkyboxAggrandie * angleBottomColorEnd);	// Bottom gradient coords

				float screenCenter = 0.5;					// Half of 0/1

				float coordTopScreen = (milieuSkyboxAggrandie - camAngle * milieuSkyboxAggrandie) - screenCenter;	// Screen bottom coords
				float coordBottomScreen = (milieuSkyboxAggrandie - camAngle * milieuSkyboxAggrandie) + screenCenter;	// Screen top coords

				fixed2 pos = screenPos / screenHeight; // Screen pixel line (0/1)

				return lerp(_BottomColor, _TopColor, clamp((lerp(coordTopScreen, coordBottomScreen, pos.y) - coordBottomColor)/(coordTopColor - coordBottomColor),0,1));
			}
			ENDCG
		}
	}
}
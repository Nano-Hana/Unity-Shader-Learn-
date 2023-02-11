// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "Unity Learn/C7_1/SingleTextrue"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)     //��������ɫ
		_MainTex ("Main Tex", 2D) = "white" {}          //����
		_Specular ("Specular", Color) = (1, 1, 1, 1)    //�߹���ɫ
		_Gloss ("Gloss", Range(8.0, 256)) = 20          //�߹ⷶΧ
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;   //ST�����źͱ任����д �����ǰ����������Ƽ�_ST
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal:TEXCOORD0;//�޸Ĳ���
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                //�Ѷ�������ת�����ü��ռ�
                o.pos = UnityObjectToClipPos(v.vertex);
                //����ռ��µķ��ߴ��ݸ�ƬԪ
                //o.worldNormal=mul(v.normal,(float3x3)unity_WorldToObject);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //��������ת����������
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                //�õ��������꣬��������ƫ�� ע�͵���ԭʼ��ʽ ʹ�õ���Unity���÷�������� ������_ST �ı���
                //o.uv =  v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                //���������������ֵ
                fixed3 worldNormal = normalize(i.worldNormal);
                //��ù��߷���
                //fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //��û���������
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //��������ģ����������� Cdiffuse=(Clight*Mdiffuse)max(0,n*l)
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal,worldLightDir));

                //��÷��䷽��
                //fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                //����ӽǷ���
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                //
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                //����߹�
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}

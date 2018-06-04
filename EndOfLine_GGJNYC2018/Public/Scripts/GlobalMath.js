// GlobalMath.js
// Version: 0.0.1
// Event: Lens Initialized
// Description: Global utility functions

if(global.math == null)
{
	global.math = {};

	global.math.lerp = function(a, b, t)
	{
	    return a * (1.0 - t) + b * t;
	}

	global.math.lerpVec3 = function (a, b, t)
	{
	    return new vec3(global.math.lerp(a.x, b.x, t), global.math.lerp(a.y, b.y, t), global.math.lerp(a.z, b.z, t));
	}

	global.math.lerpVec4 = function (a, b, t)
	{
	    return new vec4(global.math.lerp(a.x, b.x, t), global.math.lerp(a.y, b.y, t), global.math.lerp(a.z, b.z, t), global.math.lerp(a.w, b.w, t));
	}

	global.math.vecMultScalar = function(a, s)
	{
		return new vec3(a.x * s, a.y * s, a.z * s);
	}

	global.math.vecDivScalar = function(a, s)
	{
		return new vec3(a.x / s, a.y / s, a.z / s);
	}

	global.math.vecDot = function(a, b)
	{
	    return a.x * b.x + a.y * b.y + a.z * b.z;
	}

	global.math.vecCross = function(a, b)
	{
	    return new vec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
	}

	global.math.vecLength = function(a)
	{
	    return Math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
	}

	global.math.vecNormalize = function(a)
	{
	    return global.math.vecDivScalar( a, global.math.vecLength(a) );
	}

	global.math.vecAngle = function(a, b)
	{
	    return Math.acos( global.math.vecDot( a, b ) );
	}

	global.math.getLookAtRotation = function(srcPos, destPos)
	{
		var up = new vec3(0, 1, 0);

		var forward = new vec3(0, 0, 1);

		var forwardVector = global.math.vecNormalize( destPos.subVec(srcPos) );

		var dot = global.math.vecDot(forward, forwardVector);

		if(Math.abs(dot + 1.0) < 0.000001)
		{
			return( quatFromAngleAxis(Math.PI, up) );
		}

		if(Math.abs(dot - 1.0) < 0.000001)
		{
			return( new quat(0, 0, 0, 1) );
		}

		var rotAngle = Math.acos( dot );
		var rotAxis = global.math.vecNormalize( global.math.vecCross( forward, forwardVector ) );

		return quatFromAngleAxis( rotAngle, rotAxis );
	}

	global.math.transformForward = function(t)
	{
		var r = t.getWorldTransform().column2;

		return global.math.vecNormalize( new vec3(r.x, r.y, r.z) );
	}

	global.math.printVec2 = function(v)
	{
		print( v.x.toString() + ", " + v.y.toString() );
	}

	global.math.printVec3 = function(v)
	{
		print( v.x.toString() + ", " + v.y.toString() + ", " + v.z.toString() );
	}

	global.math.printVec4 = function(v)
	{
		print( v.x.toString() + ", " + v.y.toString() + ", " + v.z.toString() + ", " + v.w.toString());
	}
}
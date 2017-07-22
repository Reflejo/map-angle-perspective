# Problem 

How to transform the camera such that the bounds are centered on screen at the greatest possible zoom level while the map is tilted.

**Warning: For simplicity I'm assuming the map bearing is 0 (facing north), solving it for other bearings would just mean to add one more rotation matrix on y**

Please let me know if there is a simpler solution I didn't see :)

# Preview

![zoom](https://user-images.githubusercontent.com/232113/28444544-dcc3b644-6d72-11e7-9997-a8b233432f8e.gif)

# Explanation

The way I approached this problem is by transformation matrices. Similar to what `CATransform3D` does with `CALayer`s. So the way I formulated the problem is: assuming the rect (coord bounds) is centered on the screen at the greatest possible zoom with pitch=0 what transformation we need to apply so after applying the rotation, the rect ends up vertically centered and the resulting width equals the map width.

So the transformation needed would be: (Translation x Scale x Rotation x Perspective); where:

![solution-transform-matrix](https://user-images.githubusercontent.com/232113/28348232-b5217154-6bf0-11e7-91ac-edcb7bef3aed.png)

... `t` and `s` are the values we need to solve our system of equations for, `p` can be eye balled to `1 / -1350` and `a` is the pitch angle in degrees. Note that the `z` dimension is zero on the scale matrix which will simplify the math a bit and we don't need the `z` dimension here.

One more thing before moving on: because the rotation point needs to be in the center, we need to translate the matrix before transforming it (and after), so the resulting system would be:

![solution-transform-matrix-full](https://user-images.githubusercontent.com/232113/28348263-dd7e34fc-6bf0-11e7-9234-1c12620a1c73.png)

... where `h` is the height of the bounds in pixels. After resolving this matrix we get:

![solution-matrix](https://user-images.githubusercontent.com/232113/28348280-04105302-6bf1-11e7-835a-86edcce66de0.png)

Next in order to get the projection of a point from the non-tilted rect to the tilted rect we use a function `P(x, y)` which looks like:

![solution-px-and-py](https://user-images.githubusercontent.com/232113/28348294-167ee24c-6bf1-11e7-92ac-888276b898ce.png)

Now the base equations for solving `t` and `s` are:

### To fit to the width

1. The top-left point of the new transformed rect (in 2D) should match (height / 2 - newRectHeight / 2) to be in the center.
2. The width of the new transformed rect should match the container view.

![solution-system-width](https://user-images.githubusercontent.com/232113/28444585-134add0a-6d73-11e7-8e5b-cfe5062e5e7d.png)

.. where:

 - `w` is the width of the rect to be transformed
 - `W` is the width of the container view
 - `h` is the height of the rect to be transformed

Now if we solve the system of equations with all this information we obtain:

![solution-for-t-s-width](https://user-images.githubusercontent.com/232113/28444573-06da934e-6d73-11e7-83c5-983c718ae573.png)

### To fit to the height

1. The top-left point of new transformed rect should be (0, 0)
2. The height of the transformed rect should match the container view's height

![solution-system-height](https://user-images.githubusercontent.com/232113/28444607-3f4512ae-6d73-11e7-8fa8-53e2a690e821.png)

... where `h` is the height of the rect.

![solution-for-t-s-height](https://user-images.githubusercontent.com/232113/28493268-5f36e4d8-6ec8-11e7-900a-a20d873283a8.png)

These four equations is all the math we need to calculate the translation and the scale values. With this we can apply the scale to the bounds distance and calculate the zoom and offset the center using `t` (see implementation)

# Gestures in Fluid Interfaces — On Intent and Projection

In my last article we discussed how to craft spring animations between two endpoints that feel natural. When finishing an interactive transition, this includes picking an inital velocity that matches the one of the gesture. But that's only half the battle — just as important is finishing the transition the way the user intended to, i.e. choosing the right endpoint for the animation.

Inspired by the 2018 WWDC session ["Designing Fluid Interfaces"][Designing Fluid Interfaces], we'll discuss a fairly simple approach to aligning an animation's endpoint with the user's intent.


## Intent on the Home Screen

Let us take a close look at a gesture we use every day: changing between pages on the home screen. You might just give it a quick flick and expect to be taken to the next page. But when implementing such a gesture, how could we possibly know what the user intended to do?

If we were to take only the current scroll position into account and animate to whatever page is closest when the user releases his finger, one would be forced to swipe at least halfway over. On larger screens like on the iPad it becomes obvious that this is rather unwieldy.

Obviously we need more information than just the current scroll position in order to pick the right endpoint; more information about how we got there, so that we can make a reasonable assumption on how the user would have continued the motion. An natural thing to look at is the momentum of the gesture, and that's something `UIPanGestureRecognizer` already gives us out of the box. Note that it should probably to be a combination of position and velocity: The closer one is to the halfway point when releasing one's finger, the less velocity should be required to move it past that point. But just how much velocity is required to cover the remaining ground?


## Projection

Turns out we already have a very good intuition for how far that. We move content around the screen every day, most prominently perhaps content embedded in `UIScrollView`s. Everybody has a feeling for how fast one needs to flick to scroll a certain distance, and this application is no different: It's very reasonable to push content such that it comes to rest at (or close to) the position where we want it to be.

When a standard scroll view decelerates, the velocity with which it moves decreases exponentially over time. The default deceleration rate is `λ = 0.998`, meaning that the scroll view loses 0.2% of its velocity per millisecond: `v(t) = v_0·λ^(-1000t)`

The distance traveled is the area under the curve in a velocity-time-graph, thus the distance traveled until the content comes to rest is the integral of the velocity from zero to infinity. Luckily this integral converges and we find `s(t) = -0.001 · v_0 / log(λ)`. In the WWDC session ["Designing Fluid Interfaces"][Designing Fluid Interfaces], Apple refers to the process of finding the position at which some object comes to rest as _projection_. They provided a different formula to calculate it though!

```
// Distance travelled after decelerating to zero velocity at a constant rate
func project(initialVelocity: Float, decelerationRate: Float) -> Float {
    return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
}
```
Snippet: "Projection as presented in ["Designing Fluid Interfaces"][Designing Fluid Interfaces]."

This one I can't explain to you where it comes from. I only know that Facebook Pop [uses this equation, too][Facebook Implementation]. But they also assume an exponentially decaying velocity — and these equations for position and velocity simply don't fit together. Differentiating Facebook's equation for the distance traveled with respect to time, which would explain the projection formula above, doesn't even give the specified initial velocity for `t = 0`.

For common deceleration rates the two equations for projection [differ by less than a percent][Projection Comparison] though, so I'd suggest using the one you can reason about:

```
extension UIGestureRecognizer {
    public static func project(_ velocity: CGFloat, onto position: CGFloat, decelerationRate: UIScrollView.DecelerationRate = .normal) -> CGFloat {
        return position - 0.001 * velocity / log(decelerationRate.rawValue)
    }
}
```
Snippet: "Projection assuming an exponentially decaying velocity."

Note that the concept of projection is not limited to translational velocities in any way. It could also be applied to, say, the angular velocity from a rotation gesture.


## Choosing the Right Endpoint

Now that we have projection all figured out, let's turn our attention back towards choosing the endpoint that matches the user's intent. For one-dimensional interactions like paging on the home screen and open/closed-drawers like notification center, the process is fairly trivial: calculate the projected position and pick whatever endpoint is closest to that position.

Taking it to more dimensions is where things get a little tricky. We'll discuss a two-dimensional interaction here, and that's already difficult enough. So difficult in fact, that no one seems to really have it figured out: The system PIP on the Mac is horrendous — it doesn't respect the momentum at all. On the iPad it does, but the flicking the PIP still feels very clunky. Better implementations include the overlay in FaceTime and Twitch on iOS, but even they don't quite feel right.

A naïve approach would be treating each dimension of the gesture separately, in this case the horizontal and vertical position. That's what FaceTime and Twitch appear to be doing, but there's a problem with that: Just like we are used to giving content a quick flick when trying to scroll to the very top or bottom of a list, we may do the same to move the overlay to the top or bottom edge. However, our gestures aren't 100% precise and almost always have some momentum in a secondary unintended dimension, too. The problem with this is that very little directed momentum is enough to move past the halfway point along a given axis, and the unintended momentum in a secondary dimension is often enough. Therefore when treating each dimension separately, the overlay often swaps sides contrary to the users intent.

A potential solution I've come up with is instead treating the gesture as a whole: It has momentum along a primary axis, and if the momentum along the other axis is much smaller it was probably unintended and should not have the same weight when determining the endpoint of the gesture:

```
func intendedEndpoint(with velocity: CGVector, from currentPosition: CGPoint) -> Endpoint {
    var velocity = velocity

    // We want to reduce movement along the secondary axis of the gesture.
    if velocity.dx != 0 || velocity.dy != 0 {
        let velocityInPrimaryDirection = fmax(fabs(velocity.dx), fabs(velocity.dy))

        velocity.dx *= fabs(velocity.dx / velocityInPrimaryDirection)
        velocity.dy *= fabs(velocity.dy / velocityInPrimaryDirection)
    }

    let projectedPosition = UIGestureRecognizer.project(velocity, onto: currentPosition)
    let endpoint = self.endpoint(closestTo: projectedPosition)

    return endpoint
}
```
Snippet: "Reducing unintended momentum along a secondary axis."


## Additional Resources

I replicated the FaceTime overlay discussed in the aforementioned [WWDC session][Designing Fluid Interfaces] in a [demo project][GitHub Repository] on GitHub. It's a great session, you should really check it out. I also encourage you to play around with the endpoint computation and assure yourself that the naïve approach of treating each dimension separately doesn't quite feel right. If you have any other suggestions for computing the intended endpoint in a two-dimensional context, I'd love to hear about it!


[GitHub Repository]: https://github.com/jenox/UIKit-Playground/tree/master/02-Gestures-In-Fluid-Interfaces/ "Gestures In Fluid Interfaces"
[Designing Fluid Interfaces]: https://developer.apple.com/videos/play/wwdc2018/803/ "Designing Fluid Interfaces"
[Facebook Implementation]: https://github.com/facebook/pop/blob/92b2c5b7bcad64f7507da34f921492c71ff1d330/pop/POPDecayAnimationInternal.h#L34 "Facebook Pop on Github"
[Projection Comparison]: https://www.wolframalpha.com/input/?i=plot+1%2F1000*lambda%2F(1-lambda)+and+-1%2F(1000log(lambda))+from+0.8+to+1

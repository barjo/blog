module Icon exposing (bluesky, github, linkedin, moon, search, smiley, sun)

{-| Minimalist SVG icons.
-}

import Html exposing (Html)
import Svg exposing (..)
import Svg.Attributes exposing (..)


{-| Bluesky butterfly icon.
-}
bluesky : Html msg
bluesky =
    svg [ viewBox "0 0 24 24", width "20", height "20", fill "currentColor" ]
        [ Svg.path [ d "M12 10.8c-1.087-2.114-4.046-6.053-6.798-7.995C2.566.944 1.561 1.266.902 1.565.139 1.908 0 3.08 0 3.768c0 .69.378 5.65.624 6.479.785 2.627 3.6 3.476 6.158 3.13-4.295.59-7.532 2.478-4.25 7.006C5.845 24.26 11.382 21.207 12 17.08c.618 4.127 6.155 7.18 9.468 3.303 3.282-4.528.045-6.417-4.25-7.007 2.558.347 5.373-.502 6.158-3.129.246-.828.624-5.79.624-6.479 0-.689-.139-1.861-.902-2.203-.659-.3-1.664-.62-4.3 1.24C16.046 4.748 13.087 8.687 12 10.8" ] []
        ]


{-| GitHub octocat icon.
-}
github : Html msg
github =
    svg [ viewBox "0 0 24 24", width "20", height "20", fill "currentColor" ]
        [ Svg.path [ d "M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" ] []
        ]


{-| LinkedIn icon.
-}
linkedin : Html msg
linkedin =
    svg [ viewBox "0 0 24 24", width "20", height "20", fill "currentColor" ]
        [ Svg.path [ d "M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 01-2.063-2.065 2.064 2.064 0 112.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" ] []
        ]


{-| Moon icon (dark mode).
-}
moon : Html msg
moon =
    svg [ viewBox "0 0 24 24", width "20", height "20", fill "none", stroke "currentColor", strokeWidth "2", strokeLinecap "round", strokeLinejoin "round" ]
        [ Svg.path [ d "M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z" ] [] ]


{-| Ed's smiley icon (radical theme).
-}
smiley : Html msg
smiley =
    svg [ viewBox "0 0 24 24", width "20", height "20" ]
        [ g [ transform "rotate(-8 12 12)" ]
            [ Svg.circle [ cx "12", cy "12", r "11", fill "#f2c802", opacity "0.6", stroke "#161513", strokeWidth "1.5" ] []
            , Svg.path [ d "M7 9.5c0.8-1.2 2.2-1.2 3 0", stroke "#161513", strokeWidth "1.5", fill "none", strokeLinecap "round" ] []
            , Svg.path [ d "M14 9.5c0.8-1.2 2.2-1.2 3 0", stroke "#161513", strokeWidth "1.5", fill "none", strokeLinecap "round" ] []
            , Svg.ellipse [ cx "5.5", cy "12", Svg.Attributes.rx "2.5", Svg.Attributes.ry "1.5", fill "#d5032a", opacity "0.4" ] []
            , Svg.ellipse [ cx "18.5", cy "12", Svg.Attributes.rx "2.5", Svg.Attributes.ry "1.5", fill "#d5032a", opacity "0.4" ] []
            , Svg.path [ d "M3.5 15c1.5 8 15.5 8 17 0c-1.5-2.2-15.5-2.2-17 0z", fill "#fafafa", stroke "#161513", strokeWidth "1.2" ] []
            , Svg.path [ d "M7.5 13.7v5.5M12 13.5v6.5M16.5 13.7v5.5", stroke "#161513", strokeWidth "0.7" ] []
            ]
        ]


{-| Search / magnifying glass icon.
-}
search : Html msg
search =
    svg [ viewBox "0 0 24 24", width "20", height "20", fill "none", stroke "currentColor", strokeWidth "2", strokeLinecap "round", strokeLinejoin "round" ]
        [ Svg.circle [ cx "11", cy "11", r "8" ] []
        , Svg.path [ d "M21 21l-4.35-4.35" ] []
        ]


{-| Sun icon (light mode).
-}
sun : Html msg
sun =
    svg [ viewBox "0 0 24 24", width "20", height "20", fill "none", stroke "currentColor", strokeWidth "2", strokeLinecap "round", strokeLinejoin "round" ]
        [ Svg.circle [ cx "12", cy "12", r "5" ] []
        , Svg.path [ d "M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" ] []
        ]

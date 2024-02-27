# Mermaid examples
To render these in VS Code, you need to install an extension for Mermaid. I use [this one](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid).

Some of these examples do not render properly in GitHub but they do in VS Code with the extension installed.

## Simple flowchart
``` mermaid
flowchart TD;
    A-->B;
    A-->C;
    B-->D;
    C-->D;
    D-->E; 
```

## Flowchart with lots of connections

``` mermaid
flowchart LR;
    A-->B;
    A-->C;
    B-->D;
    C-->D;
    D-->E;
    E-->A;
    D-->C;
    D-->B;
    E-->B;
    A-->E;
    B-->A;
    B-->E;
```

## Flowchart with some colors and shapes and stuff

``` mermaid
flowchart TD
    A(Christmas) -->|Get money| B(Go shopping)
    style A fill:red,stroke:black,stroke-width:4px,shadow:shadow
    B --> C{Let me think}
    style B fill:green,stroke:black,stroke-width:4px,shadow:shadow
    C -->|One| D[Laptop]
    style C fill:blue,stroke:black,stroke-width:4px,shadow:shadow
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]
    style D fill:yellow,stroke:black,stroke-width:2px,shadow:shadow
    style E fill:brown,stroke:black,stroke-width:2px,shadow:shadow
    style F fill:navy,stroke:black,stroke-width:2px,shadow:shadow
```

## Flowchart with lots of options and neatly arranged code

``` mermaid
flowchart LR
    id1(Box with round corner)
    id2([Stadium])
    id3[(Database)]
    id4((Circle))
    id5{{Hex}}
    id6[\Parallelogram\]
    id7[\Trapezoid/]

    id1-- 1st line ---id2
    id1--> |2nd line| id3
    id1--- |3rd line| id4
    id2-.-|4th line| id5
    subgraph A box around stuf
    id3 == 5th line ==> id6
    end
    subgraph Another box around stuff
    id4 <--> id7 --> id6
    end

    style id1 fill:green,stroke:black
    style id2 fill:white,stroke:#f66,stroke-dasharray: 5, 5
    style id3 fill:#66f,stroke:#f6f,stroke-width:4px
    style id4 fill:red,stroke:yellow
    style id5 fill:orange,stroke:white
    style id6 fill:yellow,stroke:blue
    style id7 fill:brown,stroke:blue
```

# Simple gantt

``` mermaid
gantt
    title A Gantt Diagram

    Completed task            :done,    task, 2024-01-06,2024-01-08
    Active task               :active,  task2, 2024-01-09, 3d
    Future task               :         task3, after task2, 5d
    Future task2              :         task4, after task3, 5d
```

## Gant with more options

``` mermaid
gantt
    title A Gantt Diagram
    dateFormat  YYYY-MM-DD
    excludes weekends
    
    section Demo Section
    First task  : done,a1, 2023-12-24, 9d
    Second task : active,a2, 2024-01-01, 14d
    Milestone   : milestone, m1, after a2, 0d
    Critical task   : crit,a3, 2024-01-10, 9d
    Last task   : a4,after a2, 8d
    Project end : milestone, m2, 2024-02-02, 0d

    section Help the channel out
    Like      :active,a5,2024-01-5  , 2d
    Comment : a6,after a5, 7d
    Subscribe   : crit,a7,after a6,8d

```

## Pie Chart

``` mermaid
pie 
    showData
    title PetterTech's content
    "Windows 365" : 13
    "Azure" : 28
    "PowerShell" : 3
```

## Sankey diagram
``` mermaid
sankey-beta
Work-week,Writing,14
Work-week,Drawing,10
Work-week,Meetings,16
```

## Simple gitGraph diagram

``` mermaid
gitGraph:
    commit id: "Initial commit"
    commit id: "Did stuff"
    
    branch branchingOff
    
    checkout branchingOff
    commit id: "Did some branch stuff"
    commit id: "Did more branch stuff"
    checkout main
    commit id: "Did some more stuff"
    merge branchingOff id: "Merging back"

    commit id: "Post merge stuff"
    commit id: "Final?"
```
## Mindmap

``` mermaid
mindmap
  root((My brain))
    ))Dungeons & Dragons((
      {{One campaign}}
        ((DM tasks))
          Aethenia
            Kingdoms
            Cities
            Villages
            NPCs
            Deities
          Prepare
          Run
          Follow up
          Help players
      {{Another Campaign}}
        ((Halldur
        Trubadur))
          Bard
          Dwarven heritage
          Support
          Spells
          Linene
    ))YouTube((
      {{Follow up}}
        Comments
        Suggestions
      {{Create content}}
        )Azure(
          EPAC
          Arc
          AVD
          Dev Box
          Spot VMs
        Code stuff
          Powershell
          Bicep
          Mermaid
          IaC
        )Windows 365(
            Boot
            Use
            Features
            News
```

## Timeline

``` mermaid
%%{init: { 'logLevel': 'debug', 'theme': 'base' } }%%
timeline
    title PetterTech YouTube channel
    2015: Creation of channel
    2021: February <br> First video posted : June <br> Rebrand to PetterTech : October <br> First video to hit 1000 views
    2022: August <br> Reached a total of 25 uploads : September <br> First video to hit 10k views
    2023: October <br> Reached 1000 subscribers <br> : November <br> Eligible for YouTube partnership
```

## Journey

``` mermaid
    journey
        title A PetterTech day
        section Mornings
            Wake up: 1
            Eat breakfast: 5
            Walk the dog: 6
            Go to work at home office: 8
        section Working day
            Work: 8
            Lunch: 9
            Work: 7
            End work: 9
        section Evenings
            Dinner: 8
            Stuff with the kids: 8
            Walk the dog: 8
            Sleep: 8
```

## Sequence diagram

``` mermaid
sequenceDiagram
    participant Alice
    participant Bob
    Alice->>John: Hello John, how are you?
    loop Healthcheck
        John->>John: Fight against hypochondria
    end
    Note right of John: Rational thoughts <br/>prevail...
    John-->>Alice: Great!
    John->>Bob: How about you?
    Bob-->>John: Jolly good!
```

## Quadrant diagram

``` mermaid
quadrantChart
    x-axis x1 --> x2
    y-axis y1 --> y2
    quadrant-1 Comment
    quadrant-2 Like
    quadrant-3 Subscribe
    quadrant-4 Share
```

## Quadrant diagram with dots

``` mermaid
quadrantChart
    x-axis x1 --> x2
    y-axis y1 --> y2
    quadrant-1 Comment
    quadrant-2 Like
    quadrant-3 Subscribe
    quadrant-4 Share
    dot1: [0.3, 0.7]
    dot2: [0.6, 0.2]
    dot3: [0.8, 0.9]
    dot4: [0.2, 0.4]
    dot5: [0.6, 0.7]
```

## Quadrant diagram with dots, colors and stuff

``` mermaid
%%{init: {"quadrantChart": {"chartWidth": 500, "chartHeight": 500}, "themeVariables": {"quadrant1Fill": "#5abf5f","quadrant2Fill": "#24bda8","quadrant3Fill": "red","quadrant4Fill": "#bd5e24","quadrantTitleFill": "green", "quadrantPointFill": "black", "quadrantPointTextFill": "black", "quadrant1TextFill": "white", "quadrant2TextFill": "white", "quadrant3TextFill": "white", "quadrant4TextFill": "white"} }}%%
quadrantChart
    title Quadrant Diagram
    x-axis first on x --> second on x
    y-axis first on y --> second on y
    quadrant-1 Top right
    quadrant-2 Top left
    quadrant-3 Bottom left
    quadrant-4 Bottom right
    Dot1: [0.3, 0.7]
    Dot2: [0.6, 0.2]
    Dot3: [0.8, 0.9]
    Dot4: [0.2, 0.4]
    Dot5: [0.5, 0.1]
    Dot6: [0.1, 0.3]
```


## Class diagram

``` mermaid
classDiagram
class Animal {
        +name: string
        +age: int
        +makeSound(): void
    }

    class Dog {
        +breed: string
        +bark(): void
    }

    class Cat {
        +color: string
        +meow(): void
    }

    Animal <|-- Dog
    Animal <|-- Cat
```

## Relationship diagram

``` mermaid
erDiagram
    CUSTOMER }|..|{ DELIVERY-ADDRESS : has
    CUSTOMER ||--o{ ORDER : places
    CUSTOMER ||--o{ INVOICE : "liable for"
    DELIVERY-ADDRESS ||--o{ ORDER : receives
    INVOICE ||--|{ ORDER : covers
    ORDER ||--|{ ORDER-ITEM : includes
    PRODUCT-CATEGORY ||--|{ PRODUCT : contains
    PRODUCT ||--o{ ORDER-ITEM : "ordered in"
```

## State diagrams


``` mermaid
stateDiagram-v2
    [*] --> Still
    Still --> [*]
    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```

``` mermaid
stateDiagram-v2
    [*] --> Active

    state Active {
        [*] --> NumLockOff
        NumLockOff --> NumLockOn : EvNumLockPressed
        NumLockOn --> NumLockOff : EvNumLockPressed
        --
        [*] --> CapsLockOff
        CapsLockOff --> CapsLockOn : EvCapsLockPressed
        CapsLockOn --> CapsLockOff : EvCapsLockPressed
        --
        [*] --> ScrollLockOff
        ScrollLockOff --> ScrollLockOn : EvCapsLockPressed
        ScrollLockOn --> ScrollLockOff : EvCapsLockPressed
    }
```


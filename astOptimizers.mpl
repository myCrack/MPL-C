"Array" use
"Owner" use
"String" use
"control" use

"astNodeType" use

optimizeLabelsInCurrentNode: [
  node:;

  addDataToProcess: [
    copy isLabel:; recData:;
    isLabel @needToSwap.pushBack
    IndexArray @processedNodes.pushBack
    @recData AsRef @unfinishedNodes.pushBack
    0 @unfinishedIndexes.pushBack
  ];

  node.data.getTag AstNodeType.Label = [
    AstNodeType.Label @node.@data.get.@children TRUE addDataToProcess
  ] [
    node.data.getTag AstNodeType.Code = [
      AstNodeType.Code @node.@data.get FALSE addDataToProcess
    ] [
      node.data.getTag AstNodeType.Object = [
        AstNodeType.Object @node.@data.get FALSE addDataToProcess
      ] [
        node.data.getTag AstNodeType.List = [
          AstNodeType.List @node.@data.get FALSE addDataToProcess
        ] [
          # do nothing
        ] if
      ] if
    ] if
  ] if
];

optimizeLabels: [
  parserResult:;
  unfinishedNodes: IndexArray AsRef Array;
  processedNodes: IndexArray Array;
  unfinishedIndexes: Int32 Array;
  needToSwap: Cond Array;

  FALSE @needToSwap.pushBack
  IndexArray @processedNodes.pushBack
  @parserResult.@nodes AsRef @unfinishedNodes.pushBack
  0 dynamic @unfinishedIndexes.pushBack

  [
    uSize: unfinishedIndexes.dataSize 1 -;
    index: uSize unfinishedIndexes.at copy;
    nodes: @unfinishedNodes.last.data;

    index nodes.dataSize < [
      nodeIndex: index @nodes.at copy;
      nodeIndex @processedNodes.last.pushBack
      nodeIndex @parserResult.@memory.at optimizeLabelsInCurrentNode

      indexAfter: uSize @unfinishedIndexes.at;
      indexAfter 1 + @indexAfter set
      TRUE
    ] [
      needToSwap.last [
        sz: processedNodes.dataSize copy;
        src: sz 1 - @processedNodes.at;
        dst: sz 2 - @processedNodes.at;
        ll: dst.last copy;
        @dst.popBack
        src.dataSize [
          i src.at @dst.pushBack
        ] times
        ll @dst.pushBack
        @src.clear
      ] when

      lastUnfinished: @unfinishedNodes.last.@data;
      processedNodes.last @lastUnfinished set

      @needToSwap.popBack
      @processedNodes.popBack
      @unfinishedIndexes.popBack
      @unfinishedNodes.popBack

      unfinishedNodes.getSize 0 >
    ] if
  ] loop
];

optimizeNamesInCurrentNode: [
  node:;

  optimizeName: [
    nameWithInfo:;
    nameIndex: nameWithInfo.name makeStringView @nameManager.createName;
    nameIndex @nameWithInfo.@nameInfo set
  ];

  addToProcess: [
    data:;
    @data AsRef @unfinishedNodes.pushBack
    0 @unfinishedIndexes.pushBack
  ];

  (
    AstNodeType.Label           [optimizeName] # must not have children, it must be after label optimizing
    AstNodeType.Code            [addToProcess] # must not have children, it must be after label optimizing
    AstNodeType.Object          [addToProcess] # must not have children, it must be after label optimizing
    AstNodeType.List            [addToProcess] # must not have children, it must be after label optimizing
    AstNodeType.Name            [optimizeName]
    AstNodeType.NameRead        [optimizeName]
    AstNodeType.NameWrite       [optimizeName]
    AstNodeType.NameMember      [optimizeName]
    AstNodeType.NameReadMember  [optimizeName]
    AstNodeType.NameWriteMember [optimizeName]
  ) @node.@data.visit
];

optimizeNames: [
  current: nameManager: ;;

  unfinishedNodes: IndexArray AsRef Array;
  unfinishedIndexes: Int32 Array;
  @current.@nodes AsRef @unfinishedNodes.pushBack
  0 dynamic @unfinishedIndexes.pushBack

  [
    uSize: unfinishedIndexes.dataSize 1 -;
    index: uSize unfinishedIndexes.at copy;
    nodes: unfinishedNodes.last.data;

    index nodes.dataSize < [
      index nodes.at @current.@memory.at optimizeNamesInCurrentNode # reallocation here

      indexAfter: uSize @unfinishedIndexes.at;
      indexAfter 1 + @indexAfter set
      TRUE
    ] [
      @unfinishedIndexes.popBack
      @unfinishedNodes.popBack

      unfinishedNodes.getSize 0 >
    ] if
  ] loop
];

concatParserResult: [
  mresult:;
  current:;
  shift: mresult.memory.getSize;

  adjustArray: [
    indexArray:;
    @indexArray [
      cur:;
      cur shift + @cur set
    ] each
  ];

  @current.@nodes adjustArray
  @current.@memory [
    currentNode:;
    currentNode.data.getTag AstNodeType.Code = [
      AstNodeType.Code @currentNode.@data.get adjustArray
    ] [
      currentNode.data.getTag AstNodeType.List = [
        AstNodeType.List @currentNode.@data.get adjustArray
      ] [
        currentNode.data.getTag AstNodeType.Object = [
          AstNodeType.Object @currentNode.@data.get adjustArray
        ] when
      ] if
    ] if

    @currentNode move owner @mresult.@memory.pushBack
  ] each

  @current.@nodes move owner @mresult.@nodes.pushBack
];

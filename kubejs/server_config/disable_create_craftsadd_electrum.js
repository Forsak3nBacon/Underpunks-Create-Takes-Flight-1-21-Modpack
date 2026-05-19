ServerEvents.recipes(event => {
    event.remove({
        output: 'craftaddition:electrum_amulet'
    })
    
    console.info('Create: Crafts and Additions Amulet recipe has been disabled.')
})